#!/bin/bash

#
# Voice Commands Local - Installer Script
# Installs the app to /Applications and creates settings folder
#

set -e

APP_NAME="VoiceCommandsLocal.app"
INSTALL_DIR="/Applications"
DOCS_FOLDER="$HOME/Documents/Voice Commands Local"

echo "=========================================="
echo "Voice Commands Local - Installer"
echo "=========================================="
echo ""

# Check if running as root (not needed for /Applications)
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this installer as root/sudo"
    exit 1
fi

# Check if app bundle exists in current directory
if [ ! -d "$APP_NAME" ]; then
    echo "Error: $APP_NAME not found in current directory"
    exit 1
fi

# Create Documents folder
echo "Creating settings folder..."
mkdir -p "$DOCS_FOLDER"
echo "✓ Created: $DOCS_FOLDER"

# Copy app to Applications
echo ""
echo "Installing application..."
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_DIR/$APP_NAME"
fi

cp -R "$APP_NAME" "$INSTALL_DIR/"
echo "✓ Installed to: $INSTALL_DIR/$APP_NAME"

# Set permissions
chmod -R 755 "$INSTALL_DIR/$APP_NAME"

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Settings will be stored in:"
echo "  $DOCS_FOLDER"
echo ""
echo "To launch the app:"
echo "  1. Look for the waveform icon in your menu bar"
echo "  2. Or open from Applications folder"
echo ""
echo "First launch will request permissions for:"
echo "  - Microphone access"
echo "  - Speech recognition"
echo "  - Accessibility (for dictation mode)"
echo ""
