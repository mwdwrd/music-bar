#!/bin/bash
set -euo pipefail

# Music Bar — Build, Sign, Notarize, and Package
#
# Prerequisites:
#   - Apple Developer ID Application certificate in Keychain
#   - App-specific password for notarization (stored in Keychain)
#   - `create-dmg` installed: brew install create-dmg
#
# Usage:
#   ./scripts/build-dmg.sh
#
# Environment variables (or edit defaults below):
#   TEAM_ID       - Your Apple Developer Team ID
#   APPLE_ID      - Your Apple ID email
#   KEYCHAIN_PROFILE - Notarytool keychain profile name

APP_NAME="Music Bar"
BUNDLE_ID="com.temporarystudios.MusicBar"
SCHEME="MusicBar"
PROJECT="MusicBar.xcodeproj"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"

# Configure these for your signing identity
TEAM_ID="${TEAM_ID:-YOUR_TEAM_ID}"
APPLE_ID="${APPLE_ID:-your@email.com}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-MusicBar-notarize}"

echo "=== Building ${APP_NAME} ==="

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Archive
echo "Archiving..."
xcodebuild archive \
    -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    CODE_SIGN_IDENTITY="Developer ID Application" \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    CODE_SIGN_STYLE=Manual \
    2>&1 | tail -5

# Export
echo "Exporting..."
cat > "${BUILD_DIR}/ExportOptions.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${BUILD_DIR}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist" \
    2>&1 | tail -5

# Notarize
echo "Notarizing..."
# First time setup: xcrun notarytool store-credentials "${KEYCHAIN_PROFILE}" --apple-id "${APPLE_ID}" --team-id "${TEAM_ID}"
ditto -c -k --keepParent "${APP_PATH}" "${BUILD_DIR}/${APP_NAME}.zip"
xcrun notarytool submit "${BUILD_DIR}/${APP_NAME}.zip" \
    --keychain-profile "${KEYCHAIN_PROFILE}" \
    --wait

# Staple
echo "Stapling..."
xcrun stapler staple "${APP_PATH}"

# Create DMG
echo "Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 150 190 \
        --app-drop-link 450 190 \
        "${DMG_PATH}" \
        "${APP_PATH}"
else
    # Fallback to hdiutil
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${APP_PATH}" \
        -ov -format UDZO \
        "${DMG_PATH}"
fi

# Notarize the DMG too
echo "Notarizing DMG..."
xcrun notarytool submit "${DMG_PATH}" \
    --keychain-profile "${KEYCHAIN_PROFILE}" \
    --wait
xcrun stapler staple "${DMG_PATH}"

echo ""
echo "=== Done! ==="
echo "DMG: ${DMG_PATH}"
echo "Share this file with friends."
