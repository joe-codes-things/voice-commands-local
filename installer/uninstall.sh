#!/bin/bash

#
# Voice Commands Local - Uninstaller Script
# Removes the app from /Applications
#

set -e

APP_NAME="VoiceCommandsLocal.app"
INSTALL_DIR="/Applications"
DOCS_FOLDER="$HOME/Documents/Voice Commands Local"

echo "=========================================="
echo "Voice Commands Local - Uninstaller"
echo "=========================================="
echo ""

# Check if running as root (not needed for /Applications)
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this uninstaller as root/sudo"
    exit 1
fi

# Check if app is installed
if [ ! -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo "Voice Commands Local is not installed in $INSTALL_DIR"
    exit 1
fi

# Kill app if running
echo "Stopping application if running..."
pkill -f "VoiceCommandsLocal" 2>/dev/null || true
sleep 1

# Remove app
echo "Removing application..."
rm -rf "$INSTALL_DIR/$APP_NAME"
echo "✓ Removed: $INSTALL_DIR/$APP_NAME"

# Ask about settings folder
echo ""
echo "Your settings and commands are stored in:"
echo "  $DOCS_FOLDER"
echo ""
read -p "Do you want to remove your settings and commands? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$DOCS_FOLDER" ]; then
        rm -rf "$DOCS_FOLDER"
        echo "✓ Removed settings folder"
    fi
else
    echo "Settings folder preserved"
fi

echo ""
echo "=========================================="
echo "Uninstallation Complete!"
echo "=========================================="
echo ""
