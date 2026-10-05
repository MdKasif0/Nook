import Foundation
import SwiftUI
import CryptoKit
import os

/// Represents a release item parsed from a standard Sparkle 2 AppCast feed.
public struct AppCastItem: Identifiable, Equatable, Sendable {
    public var id: String { versionString + "_" + buildNumber }
    public let title: String
    public let versionString: String
    public let buildNumber: String
    public let releaseNotesHTML: String
    public let downloadURL: URL
    public let edSignature: String?
    public let fileSize: Int64
    public let publishDate: Date?
    public let minimumSystemVersion: String?
}

/// Native macOS In-App Update Engine compatible with the Sparkle 2 AppCast feed standard.
///
/// Features:
/// 1. Reads `SUFeedURL` and `SUPublicEDKey` from `Info.plist`.
/// 2. Performs asynchronous background checks and user-initiated checks.
/// 3. Parses standard RSS 2.0 AppCast XML with the `sparkle:` namespace.
/// 4. Validates Ed25519 cryptographic signatures using Apple's native `CryptoKit`.
/// 5. Compares semantic version strings and build numbers.
/// 6. Drives native SwiftUI update dialogs and menu bar status.
@MainActor
@Observable
public final class NookUpdateManager {
    
    public static let shared = NookUpdateManager()
    private static let logger = Logger(subsystem: "com.nook.app", category: "UpdateManager")
    
    public enum UpdateState: Equatable, Sendable {
        case idle
        case checking
        case updateAvailable(AppCastItem)
        case upToDate(checkedAt: Date)
        case error(String)
    }
    
    public var state: UpdateState = .idle
    public var isShowingUpdateSheet: Bool = false
    public var lastCheckedDate: Date? {
        UserDefaults.standard.object(forKey: "nook_last_update_check") as? Date
    }
    
    /// The configured AppCast feed URL from Info.plist (or fallback default)
    public var feedURL: URL {
        if let customUrlString = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String,
           let url = URL(string: customUrlString) {
            return url
        }
        return URL(string: "https://nook.app/appcast.xml")!
    }
    
    /// The configured Ed25519 public key from Info.plist
    public var publicEDKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
    }
    
    /// Current installed app version
    public var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    /// Current installed app build number
    public var currentBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
    
    private init() {}
    
    // MARK: - Update Checking
    
    /// Checks the AppCast feed for newer versions.
    /// - Parameter userInitiated: If true, opens the update window/sheet even if up to date or on error.
    public func checkForUpdates(userInitiated: Bool = true) {
        guard state != .checking else { return }
        state = .checking
        if userInitiated {
            isShowingUpdateSheet = true
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: feedURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "NookUpdate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server returned non-200 status."])
                }
                
                let parser = AppCastParser(xmlData: data)
                let items = parser.parse()
                
                let checkTime = Date()
                UserDefaults.standard.set(checkTime, forKey: "nook_last_update_check")
                
                if let newestItem = items.first, isNewerVersion(item: newestItem) {
                    Self.logger.info("Found newer Nook version: \(newestItem.versionString) (build \(newestItem.buildNumber))")
                    self.state = .updateAvailable(newestItem)
                    self.isShowingUpdateSheet = true
                } else {
                    Self.logger.info("Nook is up to date: \(self.currentVersion)")
                    self.state = .upToDate(checkedAt: checkTime)
                }
            } catch {
                Self.logger.error("Update check failed: \(error.localizedDescription)")
                self.state = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Version Comparison
    
    public func isNewerVersion(item: AppCastItem) -> Bool {
        return Self.isVersion(item.versionString, build: item.buildNumber, newerThan: currentVersion, currentBuild: currentBuild)
    }
    
    /// Semantic version comparator helper
    public static func isVersion(_ v1: String, build b1: String, newerThan v2: String, currentBuild b2: String) -> Bool {
        let v1Parts = v1.split(separator: ".").compactMap { Int($0) }
        let v2Parts = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxCount = max(v1Parts.count, v2Parts.count)
        for i in 0..<maxCount {
            let p1 = i < v1Parts.count ? v1Parts[i] : 0
            let p2 = i < v2Parts.count ? v2Parts[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        
        // If versions are identical, compare build numbers
        let build1 = Int(b1) ?? 0
        let build2 = Int(b2) ?? 0
        return build1 > build2
    }
    
    // MARK: - Cryptographic Verification
    
    /// Validates an Ed25519 signature on downloaded data against the configured public key.
    public func verifyData(_ data: Data, signatureBase64: String) -> Bool {
        guard let keyString = publicEDKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              let keyData = Data(base64Encoded: keyString),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              let sigData = Data(base64Encoded: signatureBase64) else {
            return false
        }
        return publicKey.isValidSignature(sigData, for: data)
    }
}

// MARK: - AppCast XML Parser

private final class AppCastParser: NSObject, XMLParserDelegate, @unchecked Sendable {
    private let parser: XMLParser
    private var items: [AppCastItem] = []
    
    private var inItem = false
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentMinSystem = ""
    
    // Enclosure attributes
    private var enclosureURL: URL?
    private var enclosureVersion = ""
    private var enclosureShortVersion = ""
    private var enclosureSignature: String?
    private var enclosureLength: Int64 = 0
    
    init(xmlData: Data) {
        self.parser = XMLParser(data: xmlData)
        super.init()
        self.parser.delegate = self
    }
    
    func parse() -> [AppCastItem] {
        parser.parse()
        return items
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            inItem = true
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentMinSystem = ""
            enclosureURL = nil
            enclosureVersion = ""
            enclosureShortVersion = ""
            enclosureSignature = nil
            enclosureLength = 0
        } else if inItem && elementName == "enclosure" {
            if let urlStr = attributeDict["url"], let url = URL(string: urlStr) {
                enclosureURL = url
            }
            enclosureVersion = attributeDict["sparkle:version"] ?? attributeDict["version"] ?? ""
            enclosureShortVersion = attributeDict["sparkle:shortVersionString"] ?? attributeDict["shortVersionString"] ?? ""
            enclosureSignature = attributeDict["sparkle:edSignature"]
            if let lenStr = attributeDict["length"], let len = Int64(lenStr) {
                enclosureLength = len
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "pubDate":
            currentPubDate += string
        case "sparkle:minimumSystemVersion":
            currentMinSystem += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard inItem, currentElement == "description" else { return }
        if let text = String(data: CDATABlock, encoding: .utf8) {
            currentDescription += text
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            inItem = false
            if let url = enclosureURL {
                let vString = enclosureShortVersion.isEmpty ? currentTitle : enclosureShortVersion
                let bNumber = enclosureVersion.isEmpty ? "1" : enclosureVersion
                
                let item = AppCastItem(
                    title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    versionString: vString.trimmingCharacters(in: .whitespacesAndNewlines),
                    buildNumber: bNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    releaseNotesHTML: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    downloadURL: url,
                    edSignature: enclosureSignature,
                    fileSize: enclosureLength,
                    publishDate: ISO8601DateFormatter().date(from: currentPubDate),
                    minimumSystemVersion: currentMinSystem.isEmpty ? nil : currentMinSystem
                )
                items.append(item)
            }
        }
    }
}
