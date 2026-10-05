#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Nook — Sparkle 2 AppCast Feed Generator
#
# Generates a valid Sparkle 2 XML AppCast feed with Ed25519 (Curve25519)
# digital signatures using native macOS CryptoKit.
#
# Produces:
#   - web/appcast.xml
#   - dist/appcast.xml
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEY_FILE="$PROJECT_ROOT/.sparkle_priv_key"
DMG_FILE="${1:-"$PROJECT_ROOT/dist/Nook-1.0.0-Universal.dmg"}"
OUTPUT_XML="$PROJECT_ROOT/web/appcast.xml"
DIST_XML="$PROJECT_ROOT/dist/appcast.xml"
INFO_PLIST="$PROJECT_ROOT/Nook/Info.plist"

VERSION="${VERSION:-"1.0.0"}"
BUILD_NUMBER="${BUILD_NUMBER:-"1"}"
DOWNLOAD_URL="https://nook.app/downloads/$(basename "$DMG_FILE")"

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

if [ ! -f "$DMG_FILE" ]; then
  echo "❌ Error: DMG file not found at $DMG_FILE"
  echo "   Run ./scripts/package_dmg.sh first to build the DMG."
  exit 1
fi

echo "🔐 Step 1/3: Checking / Generating Ed25519 Signing Keys..."

# Generate or load Ed25519 keypair using native Swift CryptoKit
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
print("PUBLIC_KEY=\(pubBase64)")
SWIFT_CODE
)

PUBLIC_KEY=$(echo "$KEYS_OUTPUT" | grep "PUBLIC_KEY=" | cut -d'=' -f2)
chmod 600 "$KEY_FILE" 2>/dev/null || true

echo "  • Public Key: $PUBLIC_KEY"

# Ensure Info.plist has the public key and Sparkle keys configured
if ! grep -q "SUPublicEDKey" "$INFO_PLIST"; then
  echo "  • Updating $INFO_PLIST with SUPublicEDKey and SUFeedURL..."
  /usr/libexec/PlistBuddy -c "Add :SUFeedURL string https://nook.app/appcast.xml" "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :SUFeedURL https://nook.app/appcast.xml" "$INFO_PLIST"

  /usr/libexec/PlistBuddy -c "Add :SUPublicEDKey string $PUBLIC_KEY" "$INFO_PLIST" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $PUBLIC_KEY" "$INFO_PLIST"

  /usr/libexec/PlistBuddy -c "Add :SUEnableAutomaticChecks bool true" "$INFO_PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :SUScheduledCheckInterval integer 86400" "$INFO_PLIST" 2>/dev/null || true
fi

echo "✍️  Step 2/3: Signing DMG and calculating cryptographic hash..."

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

// Verify signature with public key
let isValid = privateKey.publicKey.isValidSignature(signature, for: dmgData)
if !isValid {
    fputs("Cryptographic verification failed\n", stderr)
    exit(1)
}

print("SIGNATURE=\(sigBase64)")
print("LENGTH=\(byteLength)")
SWIFT_CODE
)

SIGNATURE=$(echo "$SIGN_OUTPUT" | grep "SIGNATURE=" | cut -d'=' -f2)
BYTE_LENGTH=$(echo "$SIGN_OUTPUT" | grep "LENGTH=" | cut -d'=' -f2)
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

echo "  • Signature: $SIGNATURE"
echo "  • Length:    $BYTE_LENGTH bytes"

echo "📄 Step 3/3: Generating Sparkle 2 AppCast Feed XML..."

mkdir -p "$(dirname "$OUTPUT_XML")"
mkdir -p "$(dirname "$DIST_XML")"

cat > "$OUTPUT_XML" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Nook Changelog &amp; Updates</title>
    <link>https://nook.app/appcast.xml</link>
    <description>Most recent updates and release notes for Nook on macOS.</description>
    <language>en</language>
    <item>
      <title>Nook $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
      <description><![CDATA[
        <h2>What's New in Nook $VERSION</h2>
        <ul>
          <li><strong>Interactive 3D Miniature Environment:</strong> Direct physical object interaction with RealityKit entities across desk, bed, shelves, audio lounge, and floor.</li>
          <li><strong>Physical Drag &amp; Drop:</strong> Smooth pick-up elevation, surface height snapping, physical settling, and boundary wall constraints.</li>
          <li><strong>Movable Prop Controls:</strong> 45° incremental rotation, constrained scaling (0.85x–1.25x), and native Undo/Redo integration.</li>
          <li><strong>Companion Cat Reactivity:</strong> Cookie looks curiously at moving objects, purrs when petted, and keeps you company.</li>
          <li><strong>Local-First Guarantee:</strong> SwiftData offline storage with persistent room coordinates and Zero-Cloud privacy.</li>
        </ul>
      ]]></description>
      <enclosure
        url="$DOWNLOAD_URL"
        sparkle:version="$BUILD_NUMBER"
        sparkle:shortVersionString="$VERSION"
        sparkle:edSignature="$SIGNATURE"
        length="$BYTE_LENGTH"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF

cp "$OUTPUT_XML" "$DIST_XML"

echo ""
echo "============================================================"
echo "🎉 SPARKLE APPCAST GENERATED SUCCESSFULLY!"
echo "============================================================"
echo "  • Feed File:     $OUTPUT_XML"
echo "  • Dist Copy:     $DIST_XML"
echo "  • App Version:   $VERSION (Build $BUILD_NUMBER)"
echo "  • Enclosure URL: $DOWNLOAD_URL"
echo "  • EdSignature:   $SIGNATURE"
echo "============================================================"
