#!/bin/bash

#
# Voice Commands Local - Uninstaller Builder
# Creates a small AppleScript .app uninstaller with a compact dialog UI
# (avoids the full macOS Installer wizard which looks identical to the installer)
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/scripts/version.sh"
BUILD_DIR="$PROJECT_ROOT/builds"
VERSION="${1:-$(read_project_version "$PROJECT_ROOT")}"
validate_release_version "$VERSION"

NUMERIC_VERSION="${VERSION#v}"
APP_NAME="Uninstall Voice Commands Local.app"
APP_PATH="$BUILD_DIR/$APP_NAME"
SCRIPT_PATH="$SCRIPT_DIR/uninstaller_temp.applescript"

echo "=========================================="
echo "Building Uninstaller App"
echo "=========================================="
echo ""

# Write the AppleScript
cat > "$SCRIPT_PATH" << 'APPLESCRIPT'
-- Voice Commands Local Uninstaller

set appPath to "/Applications/VoiceCommandsLocal.app"
set docsFolder to (POSIX path of (path to documents folder)) & "Voice Commands Local"

-- Confirm before uninstalling
set response to button returned of (display dialog "This will remove Voice Commands Local from your Mac." & return & return & "The app and all settings will be deleted." buttons {"Cancel", "Uninstall"} default button "Cancel" with title "Uninstall Voice Commands Local" with icon caution)

if response is "Uninstall" then
    -- Run removal with admin privileges
    try
        do shell script "
            pkill -f VoiceCommandsLocal 2>/dev/null || true
            sleep 1
            rm -rf '/Applications/VoiceCommandsLocal.app'
            rm -rf '" & docsFolder & "'
        " with administrator privileges
        
        display dialog "Voice Commands Local has been uninstalled." buttons {"OK"} default button "OK" with title "Uninstall Complete" with icon note
    on error errMsg
        display dialog "Uninstall failed: " & errMsg buttons {"OK"} default button "OK" with title "Uninstall Failed" with icon stop
    end try
end if
APPLESCRIPT

# Compile to .app
echo "Compiling uninstaller app..."
rm -rf "$APP_PATH"
osacompile -o "$APP_PATH" "$SCRIPT_PATH"

# Clean up temp script
rm -f "$SCRIPT_PATH"

# Get size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)

echo ""
echo "✓ Uninstaller app created: $APP_NAME ($APP_SIZE)"
echo ""