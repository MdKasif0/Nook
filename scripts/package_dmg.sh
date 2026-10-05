#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Nook — DMG Packaging & Release Distribution Script
#
# Builds Nook for macOS (15.0+), prepares a clean staging presentation with
# Nook.app and an Applications shortcut, and packages a compressed .dmg file.
#
# Supports:
#   1. Unsigned / Ad-hoc distribution (default for open-source / no Apple Dev ID)
#   2. Developer ID signed distribution (when certificate is available)
#   3. Notarization pass-through via xcrun notarytool
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
APP_NAME="Nook"
VERSION="1.0.0"
VOL_NAME="Nook"
CONFIG="Release"
DERIVED_DATA="$PROJECT_ROOT/DerivedData"
BUILD_DIR="$DERIVED_DATA/Build/Products/$CONFIG"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DIST_DIR="$PROJECT_ROOT/dist"
DMG_NAME="$APP_NAME-$VERSION-Universal.dmg"
OUTPUT_DMG="$DIST_DIR/$DMG_NAME"
WEB_DOWNLOADS_DIR="$PROJECT_ROOT/web/downloads"

# Signing configuration
SIGNING_IDENTITY="-"  # Default: Ad-hoc local / unsigned distribution
HARDENED_RUNTIME=false
NOTARIZE=false
APPLE_ID=""
TEAM_ID=""
PASSWORD=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sign)
      SIGNING_IDENTITY="$2"
      HARDENED_RUNTIME=true
      shift 2
      ;;
    --notarize)
      NOTARIZE=true
      shift
      ;;
    --apple-id)
      APPLE_ID="$2"
      shift 2
      ;;
    --team-id)
      TEAM_ID="$2"
      shift 2
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: ./scripts/package_dmg.sh [options]"
      echo ""
      echo "Options:"
      echo "  --sign <identity>    Sign with Developer ID identity (default: ad-hoc '-')"
      echo "  --notarize           Submit DMG to Apple notary service (requires credentials)"
      echo "  --apple-id <email>   Apple ID for notarytool"
      echo "  --team-id <id>       Developer Team ID"
      echo "  --password <pwd>     App-specific password or keychain item"
      echo "  --help, -h           Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo ""
echo "📦 ========================================================"
echo "📦 PACKAGING NOOK DMG FOR macOS 15+"
echo "📦 ========================================================"
echo "  • Version:            $VERSION"
echo "  • Configuration:      $CONFIG"
echo "  • Signing Identity:   $SIGNING_IDENTITY"
echo "  • Output Destination: $OUTPUT_DMG"
echo "============================================================"
echo ""

# Ensure Xcode tools
DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR

# Step 1: Clean and build Release application bundle
echo "🔨 Step 1/5: Building $APP_NAME.app (Configuration: $CONFIG)..."
xcodebuild \
  -project "$PROJECT_ROOT/Nook.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  clean build \
  | xcbeautify 2>/dev/null || xcodebuild \
  -project "$PROJECT_ROOT/Nook.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED_DATA" \
  build

if [ ! -d "$APP_BUNDLE" ]; then
  echo "❌ Error: App bundle not found at $APP_BUNDLE"
  exit 1
fi
echo "  ✅ Built: $APP_BUNDLE"

# Step 2: Code signing
echo "✍️  Step 2/5: Applying Code Signature ($SIGNING_IDENTITY)..."
if [ "$HARDENED_RUNTIME" = true ]; then
  echo "  • Applying Developer ID signature with Hardened Runtime..."
  codesign --force --deep --options runtime \
    --entitlements "$PROJECT_ROOT/Nook/Nook.entitlements" \
    --sign "$SIGNING_IDENTITY" \
    --timestamp \
    "$APP_BUNDLE"
else
  echo "  • Applying Ad-hoc signature (Unsigned distribution mode)..."
  codesign --force --deep \
    --entitlements "$PROJECT_ROOT/Nook/Nook.entitlements" \
    --sign - \
    "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo "  ✅ Signature verified."

# Step 3: Prepare clean staging folder
echo "📁 Step 3/5: Preparing DMG Staging Directory..."
STAGING_DIR="$(mktemp -d -t nook_dmg_staging_XXXXXX)"
trap 'rm -rf "$STAGING_DIR"' EXIT

# Copy app bundle into staging
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"

# Create standard Applications symlink
ln -s /Applications "$STAGING_DIR/Applications"

# Set Volume Icon if available
if [ -f "$PROJECT_ROOT/Nook/Resources/AppIcon.icns" ]; then
  cp "$PROJECT_ROOT/Nook/Resources/AppIcon.icns" "$STAGING_DIR/.VolumeIcon.icns"
  if command -v SetFile &>/dev/null; then
    SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
    SetFile -a C "$STAGING_DIR" 2>/dev/null || true
  fi
fi

# Remove hidden junk files (.DS_Store, etc.)
find "$STAGING_DIR" -name ".DS_Store" -depth -exec rm -f {} + 2>/dev/null || true

# Step 4: Package compressed read-only DMG with hdiutil
echo "💿 Step 4/5: Creating Compressed DMG ($OUTPUT_DMG)..."
mkdir -p "$DIST_DIR"
rm -f "$OUTPUT_DMG"

hdiutil create \
  -volname "$VOL_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"

# Create generic Nook.dmg symlink in dist
ln -sf "$DMG_NAME" "$DIST_DIR/Nook.dmg"

echo "  ✅ Created: $OUTPUT_DMG ($(du -h "$OUTPUT_DMG" | cut -f1))"

# Step 5: Copy to web distribution directories
echo "🌐 Step 5/5: Syncing DMG to Marketing Website Downloads..."
mkdir -p "$WEB_DOWNLOADS_DIR"
cp "$OUTPUT_DMG" "$WEB_DOWNLOADS_DIR/$DMG_NAME"
cp "$OUTPUT_DMG" "$WEB_DOWNLOADS_DIR/Nook.dmg"

# Also sync to web assets
mkdir -p "$PROJECT_ROOT/web/assets"
cp "$OUTPUT_DMG" "$PROJECT_ROOT/web/assets/Nook-1.0-Universal.dmg"

echo "  ✅ Synced DMG to website downloads."

# Step 6: Generate Sparkle 2 AppCast feed with Ed25519 signature
echo "📡 Step 6/6: Generating Sparkle 2 AppCast XML Feed..."
"$SCRIPT_DIR/generate_appcast.sh" "$OUTPUT_DMG"

# Step 7: Validate generated AppCast feed
echo "🔍 Validating Sparkle 2 AppCast Feed..."
"$SCRIPT_DIR/validate_appcast.sh" "$PROJECT_ROOT/web/appcast.xml" "$OUTPUT_DMG"

# Optional: Notarization
if [ "$NOTARIZE" = true ]; then
  if [ -n "$APPLE_ID" ] && [ -n "$TEAM_ID" ] && [ -n "$PASSWORD" ]; then
    echo "☁️  Submitting DMG to Apple Notary Service..."
    xcrun notarytool submit "$OUTPUT_DMG" \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$PASSWORD" \
      --wait
    
    echo "📎 Stapling notarization ticket to DMG..."
    xcrun stapler staple "$OUTPUT_DMG"
    echo "  ✅ Notarization complete and stapled."
  else
    echo "⚠️  Notarization skipped: Missing --apple-id, --team-id, or --password."
  fi
fi

# Print SHA256 checksum and info
echo ""
echo "============================================================"
echo "🎉 NOOK DMG PACKAGING SUCCESSFUL!"
echo "============================================================"
echo "  • DMG File:   $OUTPUT_DMG"
echo "  • File Size:  $(du -h "$OUTPUT_DMG" | cut -f1)"
echo "  • SHA256:     $(shasum -a 256 "$OUTPUT_DMG" | awk '{print $1}')"
echo "============================================================"
echo ""
