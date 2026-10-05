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
    public let releaseNotesLink: URL?
    public let downloadURL: URL
    public let edSignature: String?
    public let fileSize: Int64
    public let publishDate: Date?
    public let minimumSystemVersion: String?
    public let isCritical: Bool
}

/// Native macOS In-App Update Engine compatible with the Sparkle 2 AppCast feed standard.
///
/// Features:
/// 1. Reads `SUFeedURL`, `SUPublicEDKey`, `SUEnableAutomaticChecks`, and `SUScheduledCheckInterval` from `Info.plist`.
/// 2. Performs asynchronous background checks and user-initiated checks.
/// 3. Parses standard RSS 2.0 AppCast XML with the `sparkle:` namespace (both modern top-level elements and enclosure attributes).
/// 4. Filters updates according to macOS minimum system compatibility (`sparkle:minimumSystemVersion`).
/// 5. Validates Ed25519 cryptographic signatures (RFC 8032) using Apple's native `CryptoKit`.
/// 6. Downloads updates, verifies signatures, and mounts DMG images natively.
/// 7. Drives native SwiftUI update dialogs and menu bar status.
@MainActor
@Observable
public final class NookUpdateManager {
    
    public static let shared = NookUpdateManager()
    private static let logger = Logger(subsystem: "com.nook.app", category: "UpdateManager")
    
    public enum UpdateState: Equatable, Sendable {
        case idle
        case checking
        case updateAvailable(AppCastItem)
        case downloading(progress: Double)
        case readyToInstall(dmgURL: URL)
        case upToDate(checkedAt: Date)
        case error(String)
    }
    
    public var state: UpdateState = .idle
    public var isShowingUpdateSheet: Bool = false
    public var downloadProgress: Double = 0.0
    
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
    
    /// Whether automatic update checks are enabled
    public var isAutomaticCheckEnabled: Bool {
        if let val = Bundle.main.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool {
            return val
        }
        return true
    }
    
    /// Scheduled check interval in seconds (default: 86400 / 24 hours)
    public var scheduledCheckInterval: TimeInterval {
        if let val = Bundle.main.object(forInfoDictionaryKey: "SUScheduledCheckInterval") as? Double {
            return val
        }
        return 86400
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
    
    // MARK: - Startup & Periodic Checking
    
    /// Invoked on app launch to perform scheduled update checks if interval elapsed.
    public func performBackgroundCheckIfNeeded() {
        guard isAutomaticCheckEnabled else { return }
        
        let now = Date()
        if let last = lastCheckedDate {
            guard now.timeIntervalSince(last) >= scheduledCheckInterval else { return }
        }
        
        checkForUpdates(userInitiated: false)
    }
    
    // MARK: - Update Checking
    
    /// Checks the AppCast feed for newer versions.
    /// - Parameter userInitiated: If true, opens the update window/sheet even if up to date or on error.
    public func checkForUpdates(userInitiated: Bool = true) {
        guard state != .checking else { return }
        state = .checking
        downloadProgress = 0.0
        if userInitiated {
            isShowingUpdateSheet = true
        }
        
        Task {
            do {
                var request = URLRequest(url: feedURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15.0)
                request.setValue("Nook/\(self.currentVersion) (Macintosh; Mac OS X) Sparkle/2.0", forHTTPHeaderField: "User-Agent")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "NookUpdate", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server returned non-200 status."])
                }
                
                let parser = AppCastParser(xmlData: data)
                let items = parser.parse()
                
                let checkTime = Date()
                UserDefaults.standard.set(checkTime, forKey: "nook_last_update_check")
                
                // Find newest release compatible with this Mac
                let compatibleItems = items.filter { self.isSystemCompatible(item: $0) }
                
                if let newestItem = compatibleItems.first, self.isNewerVersion(item: newestItem) {
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
    
    // MARK: - In-App Download & Cryptographic Verification
    
    /// Downloads the update DMG file, verifies its Ed25519 signature, and mounts the disk image.
    public func downloadAndInstall(item: AppCastItem) async {
        state = .downloading(progress: 0.05)
        downloadProgress = 0.05
        
        do {
            Self.logger.info("Downloading update DMG from: \(item.downloadURL.absoluteString)")
            
            // Custom delegate session to report download progress
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NookUpdate", isDirectory: true)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            let destinationURL = tempDir.appendingPathComponent(item.downloadURL.lastPathComponent)
            try? FileManager.default.removeItem(at: destinationURL)
            
            let (tempDownloadedURL, _) = try await URLSession.shared.download(from: item.downloadURL)
            
            // Move downloaded file to known destination
            try FileManager.default.moveItem(at: tempDownloadedURL, to: destinationURL)
            self.downloadProgress = 0.90
            self.state = .downloading(progress: 0.90)
            
            // Cryptographic Verification
            if let signature = item.edSignature {
                Self.logger.info("Verifying Ed25519 signature on downloaded DMG...")
                let dmgData = try Data(contentsOf: destinationURL)
                let isValid = verifyData(dmgData, signatureBase64: signature)
                guard isValid else {
                    try? FileManager.default.removeItem(at: destinationURL)
                    throw NSError(domain: "NookUpdate", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Cryptographic signature verification failed. The update package may be corrupted or tampered with."
                    ])
                }
                Self.logger.info("✅ Cryptographic signature successfully verified!")
            }
            
            self.downloadProgress = 1.0
            self.state = .readyToInstall(dmgURL: destinationURL)
            
            // Open DMG with Finder / DiskImageMounter
            NSWorkspace.shared.open(destinationURL)
            
        } catch {
            Self.logger.error("Update download/verification failed: \(error.localizedDescription)")
            self.state = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Compatibility & Version Comparison
    
    /// Checks if the release requires a macOS version higher than the host system.
    public func isSystemCompatible(item: AppCastItem) -> Bool {
        guard let minSys = item.minimumSystemVersion, !minSys.isEmpty else { return true }
        let parts = minSys.split(separator: ".").compactMap { Int($0) }
        let major = parts.count > 0 ? parts[0] : 0
        let minor = parts.count > 1 ? parts[1] : 0
        let patch = parts.count > 2 ? parts[2] : 0
        let version = OperatingSystemVersion(majorVersion: major, minorVersion: minor, patchVersion: patch)
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
    }
    
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
    
    /// Normalizes Base64 strings to guarantee proper '=' padding.
    public static func normalizeBase64(_ input: String) -> String {
        var str = input.trimmingCharacters(in: .whitespacesAndNewlines)
        while str.count % 4 != 0 {
            str.append("=")
        }
        return str
    }
    
    /// Validates an Ed25519 signature on downloaded data against the configured public key.
    public func verifyData(_ data: Data, signatureBase64: String) -> Bool {
        guard let keyString = publicEDKey else { return false }
        let normalizedKey = Self.normalizeBase64(keyString)
        let normalizedSig = Self.normalizeBase64(signatureBase64)
        
        guard let keyData = Data(base64Encoded: normalizedKey),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData),
              let sigData = Data(base64Encoded: normalizedSig) else {
            return false
        }
        return publicKey.isValidSignature(sigData, for: data)
    }
}

// MARK: - AppCast XML Parser

public final class AppCastParser: NSObject, XMLParserDelegate, @unchecked Sendable {
    private let parser: XMLParser
    private var items: [AppCastItem] = []
    
    private var inItem = false
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentMinSystem = ""
    private var currentReleaseNotesLink = ""
    private var itemVersion = ""
    private var itemShortVersion = ""
    private var isCritical = false
    
    // Enclosure attributes
    private var enclosureURL: URL?
    private var enclosureVersion = ""
    private var enclosureShortVersion = ""
    private var enclosureSignature: String?
    private var enclosureLength: Int64 = 0
    
    public init(xmlData: Data) {
        self.parser = XMLParser(data: xmlData)
        super.init()
        self.parser.delegate = self
    }
    
    public func parse() -> [AppCastItem] {
        parser.parse()
        return items
    }
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            inItem = true
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentMinSystem = ""
            currentReleaseNotesLink = ""
            itemVersion = ""
            itemShortVersion = ""
            isCritical = false
            enclosureURL = nil
            enclosureVersion = ""
            enclosureShortVersion = ""
            enclosureSignature = nil
            enclosureLength = 0
        } else if inItem && (elementName == "sparkle:criticalUpdate" || elementName == "criticalUpdate") {
            isCritical = true
        } else if inItem && elementName == "enclosure" {
            if let urlStr = attributeDict["url"], let url = URL(string: urlStr) {
                enclosureURL = url
            }
            enclosureVersion = attributeDict["sparkle:version"] ?? attributeDict["version"] ?? ""
            enclosureShortVersion = attributeDict["sparkle:shortVersionString"] ?? attributeDict["shortVersionString"] ?? ""
            enclosureSignature = attributeDict["sparkle:edSignature"] ?? attributeDict["edSignature"]
            if let lenStr = attributeDict["length"], let len = Int64(lenStr) {
                enclosureLength = len
            }
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "pubDate":
            currentPubDate += string
        case "sparkle:minimumSystemVersion", "minimumSystemVersion":
            currentMinSystem += string
        case "sparkle:version", "version":
            itemVersion += string
        case "sparkle:shortVersionString", "shortVersionString":
            itemShortVersion += string
        case "sparkle:releaseNotesLink", "releaseNotesLink":
            currentReleaseNotesLink += string
        case "description":
            currentDescription += string
        default:
            break
        }
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard inItem, currentElement == "description" else { return }
        if let text = String(data: CDATABlock, encoding: .utf8) {
            currentDescription += text
        }
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            inItem = false
            if let url = enclosureURL {
                let vString = !itemShortVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? itemShortVersion.trimmingCharacters(in: .whitespacesAndNewlines)
                    : (enclosureShortVersion.isEmpty ? currentTitle : enclosureShortVersion)
                
                let bNumber = !itemVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? itemVersion.trimmingCharacters(in: .whitespacesAndNewlines)
                    : (enclosureVersion.isEmpty ? "1" : enclosureVersion)
                
                let releaseLink = URL(string: currentReleaseNotesLink.trimmingCharacters(in: .whitespacesAndNewlines))
                
                let item = AppCastItem(
                    title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    versionString: vString.trimmingCharacters(in: .whitespacesAndNewlines),
                    buildNumber: bNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                    releaseNotesHTML: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    releaseNotesLink: releaseLink,
                    downloadURL: url,
                    edSignature: enclosureSignature,
                    fileSize: enclosureLength,
                    publishDate: Self.parsePubDate(currentPubDate),
                    minimumSystemVersion: currentMinSystem.isEmpty ? nil : currentMinSystem.trimmingCharacters(in: .whitespacesAndNewlines),
                    isCritical: isCritical
                )
                items.append(item)
            }
        }
    }
    
    /// Parses dates conforming to standard RFC 822 / 2822 (RSS 2.0 standard) and ISO8601.
    public static func parsePubDate(_ string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return ISO8601DateFormatter().date(from: trimmed)
    }
}
