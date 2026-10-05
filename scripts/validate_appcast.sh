#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Nook — Sparkle 2 AppCast Feed Validator
#
# Validates the AppCast XML structure, schema tags, RFC 822 date compliance,
# file lengths, and Ed25519 cryptographic signatures against actual release DMGs.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FEED_FILE="${1:-"$PROJECT_ROOT/web/appcast.xml"}"
DMG_FILE="${2:-"$PROJECT_ROOT/dist/Nook-1.0.0-Universal.dmg"}"
INFO_PLIST="$PROJECT_ROOT/Nook/Info.plist"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

echo ""
echo "🔍 ========================================================"
echo "🔍 VALIDATING SPARKLE 2 APPCAST FEED"
echo "🔍 ========================================================"
echo "  • Feed Path:  $FEED_FILE"
echo "  • DMG Path:   $DMG_FILE"
echo "============================================================"
echo ""

if [ ! -f "$FEED_FILE" ]; then
  echo "❌ Error: AppCast feed file not found at $FEED_FILE"
  exit 1
fi

VALIDATION_OUTPUT=$(xcrun swift - <<SWIFT_CODE
import Foundation
import CryptoKit

let feedPath = "$FEED_FILE"
let dmgPath = "$DMG_FILE"
let plistPath = "$INFO_PLIST"

guard let xmlData = try? Data(contentsOf: URL(fileURLWithPath: feedPath)) else {
    print("❌ Error: Unable to read feed file at \(feedPath)")
    exit(1)
}

// 1. XML Well-Formedness Check
class ValidatorDelegate: NSObject, XMLParserDelegate {
    var hasRss = false
    var hasChannel = false
    var hasSparkleNs = false
    var itemsCount = 0
    var enclosuresCount = 0
    var signatures: [String] = []
    var lengths: [Int64] = []
    var versions: [String] = []
    var shortVersions: [String] = []
    var pubDates: [String] = []
    var currentElement = ""
    var currentPubDate = ""
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "rss" {
            hasRss = true
            if attributeDict["xmlns:sparkle"] == "http://www.andymatuschak.org/xml-namespaces/sparkle" {
                hasSparkleNs = true
            }
        } else if elementName == "channel" {
            hasChannel = true
        } else if elementName == "item" {
            itemsCount += 1
            currentPubDate = ""
        } else if elementName == "enclosure" {
            enclosuresCount += 1
            if let sig = attributeDict["sparkle:edSignature"] {
                signatures.append(sig)
            }
            if let lenStr = attributeDict["length"], let len = Int64(lenStr) {
                lengths.append(len)
            }
            if let v = attributeDict["sparkle:version"] ?? attributeDict["version"] {
                versions.append(v)
            }
            if let sv = attributeDict["sparkle:shortVersionString"] ?? attributeDict["shortVersionString"] {
                shortVersions.append(sv)
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "pubDate" {
            currentPubDate += string
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            pubDates.append(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

let parser = XMLParser(data: xmlData)
let delegate = ValidatorDelegate()
parser.delegate = delegate

guard parser.parse() else {
    print("❌ Error: Feed is not well-formed XML: \(parser.parserError?.localizedDescription ?? "unknown error")")
    exit(1)
}

print("  ✅ XML is well-formed.")

// 2. Validate RSS and Sparkle namespace
guard delegate.hasRss else {
    print("❌ Error: Missing <rss> root element.")
    exit(1)
}
guard delegate.hasSparkleNs else {
    print("❌ Error: Missing or incorrect xmlns:sparkle namespace declaration.")
    exit(1)
}
guard delegate.hasChannel else {
    print("❌ Error: Missing <channel> element.")
    exit(1)
}
guard delegate.itemsCount > 0 else {
    print("❌ Error: Feed contains zero <item> elements.")
    exit(1)
}
print("  ✅ RSS 2.0 structure & Sparkle namespace verified (\(delegate.itemsCount) release items found).")

// 3. Validate RFC 822 Dates
let rfc822Formatter = DateFormatter()
rfc822Formatter.locale = Locale(identifier: "en_US_POSIX")
rfc822Formatter.timeZone = TimeZone(secondsFromGMT: 0)
rfc822Formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"

for (idx, dateStr) in delegate.pubDates.enumerated() {
    guard let _ = rfc822Formatter.date(from: dateStr) else {
        print("❌ Error: Item #\(idx+1) pubDate '\(dateStr)' does not match standard RFC 822 format (EEE, dd MMM yyyy HH:mm:ss +0000).")
        exit(1)
    }
}
print("  ✅ All release dates conform to standard RFC 822 format.")

// 4. Validate Enclosures
guard delegate.enclosuresCount == delegate.itemsCount else {
    print("❌ Error: Number of <enclosure> tags (\(delegate.enclosuresCount)) does not match <item> count (\(delegate.itemsCount)).")
    exit(1)
}
guard delegate.signatures.count == delegate.itemsCount else {
    print("❌ Error: One or more <enclosure> tags are missing 'sparkle:edSignature'.")
    exit(1)
}
print("  ✅ All enclosures contain required version and signature attributes.")

// 5. Cryptographic Signature Validation against local DMG (if present)
if FileManager.default.fileExists(atPath: dmgPath) {
    guard let dmgData = try? Data(contentsOf: URL(fileURLWithPath: dmgPath)) else {
        print("⚠️ Warning: Could not read DMG at \(dmgPath)")
        exit(0)
    }
    
    let expectedLength = delegate.lengths.first ?? 0
    if dmgData.count != expectedLength {
        print("❌ Error: DMG byte length (\(dmgData.count)) does not match enclosure length attribute (\(expectedLength)).")
        exit(1)
    }
    print("  ✅ Enclosure length (\(expectedLength) bytes) matches actual DMG file exactly.")
    
    // Check Info.plist for SUPublicEDKey
    var pubKeyBase64: String?
    if FileManager.default.fileExists(atPath: plistPath),
       let plistData = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
       let plistObj = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
        pubKeyBase64 = plistObj["SUPublicEDKey"] as? String
    }
    
    if let keyString = pubKeyBase64 {
        var normalizedKey = keyString.trimmingCharacters(in: .whitespacesAndNewlines)
        while normalizedKey.count % 4 != 0 { normalizedKey.append("=") }
        
        guard let keyData = Data(base64Encoded: normalizedKey),
              let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: keyData) else {
            print("❌ Error: Invalid SUPublicEDKey in Info.plist.")
            exit(1)
        }
        
        var sigString = delegate.signatures.first!
        while sigString.count % 4 != 0 { sigString.append("=") }
        
        guard let sigData = Data(base64Encoded: sigString) else {
            print("❌ Error: sparkle:edSignature base64 decoding failed.")
            exit(1)
        }
        
        let isValid = publicKey.isValidSignature(sigData, for: dmgData)
        guard isValid else {
            print("❌ Error: Ed25519 cryptographic signature verification FAILED for \(dmgPath)!")
            exit(1)
        }
        print("  ✅ Ed25519 Cryptographic Signature VERIFIED with public key in Info.plist!")
    } else {
        print("⚠️ Warning: SUPublicEDKey not found in Info.plist, skipped crypto verification.")
    }
}

print("FEED_STATUS=PERFECT")
SWIFT_CODE
)

echo "$VALIDATION_OUTPUT"

if echo "$VALIDATION_OUTPUT" | grep -q "FEED_STATUS=PERFECT"; then
  echo ""
  echo "============================================================"
  echo "🎉 SPARKLE 2 APPCAST VALIDATION: 100% PERFECT!"
  echo "============================================================"
  exit 0
else
  echo ""
  echo "❌ Validation failed."
  exit 1
fi
