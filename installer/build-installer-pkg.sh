#!/bin/bash

#
# Voice Commands Local - Installer Package Builder
# Creates a proper macOS .pkg installer
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/scripts/version.sh"
BUILD_DIR="$PROJECT_ROOT/builds"
VERSION="${1:-$(read_project_version "$PROJECT_ROOT")}"
validate_release_version "$VERSION"
APP_SOURCE="${2:-}"

# Extract numeric version
NUMERIC_VERSION="${VERSION#v}"

APP_NAME="VoiceCommandsLocal.app"
PKG_NAME="VoiceCommandsLocal_${VERSION}_Installer.pkg"
TEMP_DIR="$SCRIPT_DIR/pkg_temp"
PAYLOAD_DIR="$TEMP_DIR/payload"
SCRIPTS_DIR="$TEMP_DIR/scripts"
COMPONENT_PLIST="$TEMP_DIR/component.plist"

echo "=========================================="
echo "Building Installer Package"
echo "=========================================="
echo ""

# Determine app source location
if [ -n "$APP_SOURCE" ]; then
    APP_PATH="$APP_SOURCE"
elif [ -d "$BUILD_DIR/VoiceCommandsLocal_${VERSION}.app" ]; then
    APP_PATH="$BUILD_DIR/VoiceCommandsLocal_${VERSION}.app"
else
    echo "Error: App not found"
    exit 1
fi

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Clean and create directories
rm -rf "$TEMP_DIR"
mkdir -p "$PAYLOAD_DIR"
mkdir -p "$SCRIPTS_DIR"

# Copy app to payload root (install-location /Applications means this lands at /Applications/VoiceCommandsLocal.app)
echo "Preparing payload..."
cp -R "$APP_PATH" "$PAYLOAD_DIR/$APP_NAME"

# Generate component plist and disable relocation so the app always installs to /Applications
# Without this, macOS Installer silently skips the payload if the app isn't already present
pkgbuild --analyze --root "$PAYLOAD_DIR" "$COMPONENT_PLIST"
/usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$COMPONENT_PLIST"
/usr/libexec/PlistBuddy -c "Set :0:BundleIsVersionChecked false" "$COMPONENT_PLIST"

# postinstall: create the Documents settings folder and install blank slate JSON files
# Only writes files if they don't already exist (preserves data on reinstall)
cat > "$SCRIPTS_DIR/postinstall" << 'EOF'
#!/bin/bash

CURRENT_USER=$(stat -f "%Su" /dev/console)
USER_HOME=$(eval echo ~$CURRENT_USER)
DOCS_FOLDER="$USER_HOME/Documents/Voice Commands Local"

mkdir -p "$DOCS_FOLDER"
chown -R "$CURRENT_USER:staff" "$DOCS_FOLDER"

# Install blank settings.json if not already present
SETTINGS_FILE="$DOCS_FOLDER/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    cat > "$SETTINGS_FILE" << 'JSON'
{
  "activationPhrase" : "",
  "commandMode" : "⌘1",
  "commandModeVoiceShortcut" : "",
  "dictation" : "⌘2",
  "dictationModeVoiceShortcut" : "",
  "stopListeningVoiceShortcut" : "",
  "toggleListening" : "⌘L"
}
JSON
    chown "$CURRENT_USER:staff" "$SETTINGS_FILE"
fi

# Install blank voice-commands.json if not already present
COMMANDS_FILE="$DOCS_FOLDER/voice-commands.json"
if [ ! -f "$COMMANDS_FILE" ]; then
    cat > "$COMMANDS_FILE" << 'JSON'
{
  "commands" : [],
  "createdAt" : "2026-01-01T00:00:00Z",
  "modifiedAt" : "2026-01-01T00:00:00Z",
  "version" : "1.0"
}
JSON
    chown "$CURRENT_USER:staff" "$COMMANDS_FILE"
fi

exit 0
EOF

chmod +x "$SCRIPTS_DIR/postinstall"

# Build the package with component plist to enforce install location
echo "Building package..."
pkgbuild --root "$PAYLOAD_DIR" \
    --component-plist "$COMPONENT_PLIST" \
    --scripts "$SCRIPTS_DIR" \
    --identifier "com.voicecommands.local" \
    --version "$NUMERIC_VERSION" \
    --install-location "/Applications" \
    "$BUILD_DIR/$PKG_NAME"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "✓ Installer package created: $PKG_NAME"
echo ""