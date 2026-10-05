#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Nook — Sparkle 2 AppCast Feed Generator
#
# Generates and maintains a fully Sparkle 2 compliant XML AppCast feed with
# Ed25519 (RFC 8032) digital signatures using native macOS CryptoKit.
#
# Produces:
#   - web/appcast.xml
#   - dist/appcast.xml
#   - web/releases/<version>.html
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEY_FILE="${SPARKLE_KEY_FILE:-"$PROJECT_ROOT/.sparkle_priv_key"}"
DMG_FILE="${1:-"$PROJECT_ROOT/dist/Nook-1.0.0-Universal.dmg"}"
OUTPUT_XML="$PROJECT_ROOT/web/appcast.xml"
DIST_XML="$PROJECT_ROOT/dist/appcast.xml"
RELEASES_DIR="$PROJECT_ROOT/web/releases"
INFO_PLIST="$PROJECT_ROOT/Nook/Info.plist"

VERSION="${VERSION:-"1.0.0"}"
BUILD_NUMBER="${BUILD_NUMBER:-"1"}"
MIN_SYSTEM_VERSION="${MIN_SYSTEM_VERSION:-"15.0"}"
FEED_URL="${FEED_URL:-"https://nook.app/appcast.xml"}"
DOWNLOAD_URL="${DOWNLOAD_URL:-"https://nook.app/downloads/$(basename "$DMG_FILE")"}"
RELEASE_NOTES_URL="https://nook.app/releases/${VERSION}.html"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

if [ ! -f "$DMG_FILE" ]; then
  echo "❌ Error: DMG file not found at $DMG_FILE"
  echo "   Run ./scripts/package_dmg.sh first to build the DMG."
  exit 1
fi

echo ""
echo "📡 ========================================================"
echo "📡 GENERATING SPARKLE 2 APPCAST FEED"
echo "📡 ========================================================"
echo "  • Version:            $VERSION (Build $BUILD_NUMBER)"
echo "  • Minimum macOS:      $MIN_SYSTEM_VERSION"
echo "  • Target DMG:         $DMG_FILE"
echo "  • Key File:           $KEY_FILE"
echo "  • AppCast Feed:       $OUTPUT_XML"
echo "============================================================"
echo ""

# ------------------------------------------------------------------------------
# Step 1: Manage Ed25519 Cryptographic Keys
# ------------------------------------------------------------------------------
echo "🔐 Step 1/4: Checking / Generating Ed25519 Signing Keys..."

KEYS_OUTPUT=$(xcrun swift - <<SWIFT_CODE
import Foundation
import CryptoKit

let keyPath = "$KEY_FILE"
let privateKey: Curve25519.Signing.PrivateKey

if FileManager.default.fileExists(atPath: keyPath),
   let keyData = try? String(contentsOfFile: keyPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
   let rawData = Data(base64Encoded: keyData),
   let loadedKey = try? Curve25519.Signing.PrivateKey(rawRepresentation: rawData) {
    privateKey = loadedKey
} else {
    privateKey = Curve25519.Signing.PrivateKey()
    let privBase64 = privateKey.rawRepresentation.base64EncodedString()
    try? privBase64.write(toFile: keyPath, atomically: true, encoding: .utf8)
}

let pubBase64 = privateKey.publicKey.rawRepresentation.base64EncodedString()
print("PUBLIC_KEY:" + pubBase64)
SWIFT_CODE
)

PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | grep "^PUBLIC_KEY:" | sed 's/^PUBLIC_KEY://')
chmod 600 "$KEY_FILE" 2>/dev/null || true

echo "  • Public Key: $PUBLIC_KEY"

# Ensure Info.plist is updated with the matching public key and feed URL
if [ -f "$INFO_PLIST" ]; then
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string $FEED_URL" "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :SUFeedURL $FEED_URL" "$INFO_PLIST" 2>/dev/null || true

  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $PUBLIC_KEY" "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $PUBLIC_KEY" "$INFO_PLIST" 2>/dev/null || true

  /usr/libexec/PlistBuddy -c "Add :SUEnableAutomaticChecks bool true" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :SUScheduledCheckInterval integer 86400" "$INFO_PLIST" 2>/dev/null || true
  echo "  ✅ Synced SUPublicEDKey and SUFeedURL to $INFO_PLIST"
fi

# ------------------------------------------------------------------------------
# Step 2: Sign DMG with Ed25519 Private Key
# ------------------------------------------------------------------------------
echo "✍️  Step 2/4: Computing Ed25519 Signature over DMG..."

SIGN_OUTPUT=$(xcrun swift - <<SWIFT_CODE
import Foundation
import CryptoKit

let keyPath = "$KEY_FILE"
let dmgPath = "$DMG_FILE"

guard let keyString = try? String(contentsOfFile: keyPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
      let keyData = Data(base64Encoded: keyString),
      let privateKey = try? Curve25519.Signing.PrivateKey(rawRepresentation: keyData) else {
    fputs("Error loading private key\n", stderr)
    exit(1)
}

guard let dmgData = try? Data(contentsOf: URL(fileURLWithPath: dmgPath)) else {
    fputs("Error reading DMG file\n", stderr)
    exit(1)
}

let signature = try! privateKey.signature(for: dmgData)
let sigBase64 = signature.base64EncodedString()
let byteLength = dmgData.count

// Internal cryptographic verification pass
let isValid = privateKey.publicKey.isValidSignature(signature, for: dmgData)
if !isValid {
    fputs("Cryptographic verification failed\n", stderr)
    exit(1)
}

print("SIGNATURE:" + sigBase64)
print("LENGTH:" + String(byteLength))
SWIFT_CODE
)

SIGNATURE=$(echo "$SIGN_OUTPUT" | grep "^SIGNATURE:" | sed 's/^SIGNATURE://')
BYTE_LENGTH=$(echo "$SIGN_OUTPUT" | grep "^LENGTH:" | sed 's/^LENGTH://')
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

echo "  • Signature: $SIGNATURE"
echo "  • Length:    $BYTE_LENGTH bytes"
echo "  • PubDate:   $PUB_DATE"

# ------------------------------------------------------------------------------
# Step 3: Generate Web Release Notes Page
# ------------------------------------------------------------------------------
echo "📝 Step 3/4: Generating Web Release Notes Page..."
mkdir -p "$RELEASES_DIR"
RELEASE_HTML_FILE="$RELEASES_DIR/${VERSION}.html"

cat > "$RELEASE_HTML_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nook $VERSION Release Notes</title>
  <meta name="description" content="Release notes and updates for Nook version $VERSION on macOS.">
  <link rel="stylesheet" href="../index.css">
  <style>
    .release-page {
      max-width: 680px;
      margin: 0 auto;
      padding: 60px 24px 100px;
      font-family: var(--font-sans, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif);
      color: #332B25;
      background: #FAF7F2;
      min-height: 100vh;
    }
    .release-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: #7A846E20;
      color: #7A846E;
      font-size: 13px;
      font-weight: 600;
      padding: 4px 12px;
      border-radius: 999px;
      margin-bottom: 16px;
    }
    .release-title {
      font-size: 32px;
      font-weight: 700;
      margin: 0 0 8px;
      color: #2D2520;
    }
    .release-date {
      font-size: 14px;
      color: #7C7267;
      margin-bottom: 32px;
    }
    .release-card {
      background: #FFFFFF;
      border: 1px solid rgba(135, 125, 115, 0.15);
      border-radius: 16px;
      padding: 28px;
      box-shadow: 0 8px 24px rgba(60, 50, 40, 0.04);
      margin-bottom: 24px;
    }
    .release-card h2 {
      font-size: 20px;
      font-weight: 600;
      margin: 0 0 16px;
      color: #2D2520;
    }
    .release-list {
      list-style: none;
      padding: 0;
      margin: 0;
    }
    .release-list li {
      position: relative;
      padding-left: 28px;
      margin-bottom: 14px;
      line-height: 1.55;
      font-size: 15px;
    }
    .release-list li::before {
      content: "✦";
      position: absolute;
      left: 6px;
      color: #7A846E;
      font-size: 14px;
    }
    .release-meta {
      font-size: 13px;
      color: #8C8074;
      line-height: 1.6;
      border-top: 1px solid rgba(135, 125, 115, 0.12);
      padding-top: 16px;
      margin-top: 24px;
    }
    .download-action {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: #7A846E;
      color: #FFFFFF;
      font-weight: 600;
      font-size: 15px;
      padding: 12px 24px;
      border-radius: 12px;
      text-decoration: none;
      transition: background 0.2s ease, transform 0.1s ease;
      margin-top: 8px;
    }
    .download-action:hover {
      background: #68725C;
      transform: translateY(-1px);
    }
  </style>
</head>
<body>
  <div class="release-page">
    <a href="../" style="text-decoration: none; color: #7A846E; font-size: 14px; font-weight: 500; display: inline-block; margin-bottom: 24px;">← Back to Nook</a>
    <div>
      <span class="release-badge">macOS 15.0+ Compatible</span>
      <h1 class="release-title">Nook $VERSION</h1>
      <div class="release-date">Released on $PUB_DATE • Build $BUILD_NUMBER</div>
    </div>

    <div class="release-card">
      <h2>What's New in this Release</h2>
      <ul class="release-list">
        <li><strong>Interactive 3D Miniature Environment:</strong> Direct physical object interaction with RealityKit entities across desk, bed, shelves, audio lounge, and floor.</li>
        <li><strong>Physical Drag &amp; Drop:</strong> Smooth pick-up elevation, surface height snapping, physical settling, and boundary wall constraints.</li>
        <li><strong>Movable Prop Controls:</strong> 45° incremental rotation, constrained scaling (0.85x–1.25x), and native Undo/Redo integration.</li>
        <li><strong>Companion Cat Reactivity:</strong> Cookie looks curiously at moving objects, purrs when petted, and keeps you company.</li>
        <li><strong>Local-First Guarantee:</strong> SwiftData offline storage with persistent room coordinates and Zero-Cloud privacy.</li>
        <li><strong>Built-in Sparkle 2 Auto-Updater:</strong> Seamless in-app update checks, Ed25519 cryptographic verification, and one-click DMG mounting.</li>
      </ul>

      <div style="margin-top: 24px;">
        <a href="$DOWNLOAD_URL" class="download-action">
          <span>Download Nook $VERSION DMG</span>
        </a>
      </div>

      <div class="release-meta">
        <div><strong>Package:</strong> $(basename "$DMG_FILE") ($BYTE_LENGTH bytes)</div>
        <div><strong>Ed25519 Signature:</strong> <code style="word-break: break-all; font-size: 11px;">$SIGNATURE</code></div>
      </div>
    </div>
  </div>
</body>
</html>
EOF

echo "  ✅ Created: $RELEASE_HTML_FILE"

# ------------------------------------------------------------------------------
# Step 4: Build Sparkle 2 AppCast Feed XML (with Multi-Release History)
# ------------------------------------------------------------------------------
echo "📄 Step 4/4: Assembling Sparkle 2 AppCast XML Feed..."

mkdir -p "$(dirname "$OUTPUT_XML")"
mkdir -p "$(dirname "$DIST_XML")"

# Merge with existing appcast items if present, or create fresh feed
xcrun swift - <<SWIFT_CODE
import Foundation

let outputXmlPath = "$OUTPUT_XML"
let distXmlPath = "$DIST_XML"

let newVersion = "$VERSION"
let newBuild = "$BUILD_NUMBER"
let newMinSys = "$MIN_SYSTEM_VERSION"
let newUrl = "$DOWNLOAD_URL"
let newSig = "$SIGNATURE"
let newLength = "$BYTE_LENGTH"
let newPubDate = "$PUB_DATE"
let newReleaseNotesUrl = "$RELEASE_NOTES_URL"

let newItemXml = """
    <item>
      <title>Nook \\(newVersion)</title>
      <pubDate>\\(newPubDate)</pubDate>
      <sparkle:version>\\(newBuild)</sparkle:version>
      <sparkle:shortVersionString>\\(newVersion)</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>\\(newMinSys)</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>\\(newReleaseNotesUrl)</sparkle:releaseNotesLink>
      <description><![CDATA[
        <h2>What's New in Nook \\(newVersion)</h2>
        <ul>
          <li><strong>Interactive 3D Miniature Environment:</strong> Direct physical object interaction with RealityKit entities across desk, bed, shelves, audio lounge, and floor.</li>
          <li><strong>Physical Drag &amp; Drop:</strong> Smooth pick-up elevation, surface height snapping, physical settling, and boundary wall constraints.</li>
          <li><strong>Movable Prop Controls:</strong> 45° incremental rotation, constrained scaling (0.85x–1.25x), and native Undo/Redo integration.</li>
          <li><strong>Companion Cat Reactivity:</strong> Cookie looks curiously at moving objects, purrs when petted, and keeps you company.</li>
          <li><strong>Local-First Guarantee:</strong> SwiftData offline storage with persistent room coordinates and Zero-Cloud privacy.</li>
          <li><strong>Built-in Sparkle 2 Auto-Updater:</strong> Seamless in-app update checks, Ed25519 cryptographic verification, and one-click DMG mounting.</li>
        </ul>
      ]]></description>
      <enclosure
        url="\\(newUrl)"
        sparkle:version="\\(newBuild)"
        sparkle:shortVersionString="\\(newVersion)"
        sparkle:edSignature="\\(newSig)"
        length="\\(newLength)"
        type="application/x-apple-diskimage" />
    </item>
"""

var existingItems: [String] = []

if FileManager.default.fileExists(atPath: outputXmlPath),
   let existingXml = try? String(contentsOfFile: outputXmlPath, encoding: .utf8) {
    // Extract existing <item> blocks
    let itemPattern = "<item>[\\\\s\\\\S]*?<\\\\/item>"
    if let regex = try? NSRegularExpression(pattern: itemPattern, options: []) {
        let nsRange = NSRange(existingXml.startIndex..<existingXml.endIndex, in: existingXml)
        let matches = regex.matches(in: existingXml, range: nsRange)
        for match in matches {
            if let range = Range(match.range, in: existingXml) {
                let itemStr = String(existingXml[range])
                // Omit item if it matches the new version/build to avoid duplicates
                if !itemStr.contains("Nook \\(newVersion)<") && !itemStr.contains("sparkle:shortVersionString=\\"\\(newVersion)\\"") {
                    existingItems.append("    " + itemStr.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }
}

var allItems = [newItemXml]
allItems.append(contentsOf: existingItems)
let itemsBlock = allItems.joined(separator: "\n\n")

let fullXml = """
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Nook Changelog &amp; Updates</title>
    <link>https://nook.app/appcast.xml</link>
    <description>Most recent updates and release notes for Nook on macOS.</description>
    <language>en</language>
\\(itemsBlock)
  </channel>
</rss>
"""

try! fullXml.write(toFile: outputXmlPath, atomically: true, encoding: .utf8)
try! fullXml.write(toFile: distXmlPath, atomically: true, encoding: .utf8)
SWIFT_CODE

echo ""
echo "============================================================"
echo "🎉 SPARKLE 2 APPCAST FEED GENERATED SUCCESSFULLY!"
echo "============================================================"
echo "  • Feed File:         $OUTPUT_XML"
echo "  • Dist Copy:         $DIST_XML"
echo "  • Version:           $VERSION (Build $BUILD_NUMBER)"
echo "  • Min System:        macOS $MIN_SYSTEM_VERSION+"
echo "  • Enclosure URL:     $DOWNLOAD_URL"
echo "  • Ed25519 Signature: $SIGNATURE"
echo "  • Release Notes:     $RELEASE_NOTES_URL"
echo "============================================================"
echo ""
