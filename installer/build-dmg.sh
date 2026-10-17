#!/bin/bash

#
# Voice Commands Local - DMG Builder
# Creates a distributable DMG with installer, uninstaller app, and manual
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/scripts/version.sh"
BUILD_DIR="$PROJECT_ROOT/builds"
VERSION="${1:-$(read_project_version "$PROJECT_ROOT")}"
validate_release_version "$VERSION"
APP_SOURCE="${2:-}"

DMG_NAME="VoiceCommandsLocal_${VERSION}_Installer.dmg"
TEMP_DMG_DIR="$SCRIPT_DIR/dmg_temp"

echo "=========================================="
echo "Voice Commands Local - DMG Builder"
echo "=========================================="
echo ""
echo "Version: $VERSION"
echo ""

# Build installer package (pass app source if provided)
echo "Building installer package..."
if [ -n "$APP_SOURCE" ]; then
    "$SCRIPT_DIR/build-installer-pkg.sh" "$VERSION" "$APP_SOURCE"
else
    "$SCRIPT_DIR/build-installer-pkg.sh" "$VERSION"
fi

# Build uninstaller app
echo "Building uninstaller app..."
"$SCRIPT_DIR/build-uninstaller-pkg.sh" "$VERSION"

# Check outputs
INSTALLER_PKG="$BUILD_DIR/VoiceCommandsLocal_${VERSION}_Installer.pkg"
UNINSTALLER_APP="$BUILD_DIR/Uninstall Voice Commands Local.app"

if [ ! -f "$INSTALLER_PKG" ]; then
    echo "Error: Installer package not found"
    exit 1
fi

if [ ! -d "$UNINSTALLER_APP" ]; then
    echo "Error: Uninstaller app not found"
    exit 1
fi

# Clean and create temp directory
echo ""
echo "Preparing DMG contents..."
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy installer package
echo "Copying installer..."
cp "$INSTALLER_PKG" "$TEMP_DMG_DIR/Install Voice Commands Local.pkg"

# Copy uninstaller app
echo "Copying uninstaller..."
cp -R "$UNINSTALLER_APP" "$TEMP_DMG_DIR/Uninstall Voice Commands Local.app"

# Copy user manual
echo "Copying user manual..."
cp "$PROJECT_ROOT/README.md" "$TEMP_DMG_DIR/User Manual.md"

# Create DMG
echo ""
echo "Creating DMG..."
DMG_PATH="$BUILD_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

hdiutil create -volname "Voice Commands Local $VERSION" \
    -srcfolder "$TEMP_DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up temp directory and intermediate files
rm -rf "$TEMP_DMG_DIR"
echo "Cleaning up intermediate files..."
rm -f "$INSTALLER_PKG"
rm -rf "$UNINSTALLER_APP"

DMG_SIZE=$(du -sh "$DMG_PATH" | cut -f1)

echo ""
echo "=========================================="
echo "DMG Created Successfully!"
echo "=========================================="
echo "File: $DMG_NAME"
echo "Size: $DMG_SIZE"
echo "Location: $BUILD_DIR"
echo ""
echo "DMG Contents:"
echo "  - Install Voice Commands Local.pkg"
echo "  - Uninstall Voice Commands Local.app"
echo "  - User Manual.md"
echo ""
