#!/bin/bash

#
# Voice Commands Local - Unified DMG Build Pipeline
# Builds the app and creates a distributable DMG with installer/uninstaller
# Does NOT leave a separate app copy in builds folder
#
# Reads MARKETING_VERSION from the XcodeGen project specification.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/version.sh"
PROJECT_PATH="$PROJECT_ROOT/VoiceCommandsLocal/VoiceCommandsLocal.xcodeproj"
BUILD_DIR="$PROJECT_ROOT/builds"
VERSION="${1:-$(read_project_version "$PROJECT_ROOT")}"
validate_release_version "$VERSION"

# Extract numeric version for Xcode (e.g., "v0.0.56" -> "0.0.56")
NUMERIC_VERSION="${VERSION#v}"

DMG_NAME="VoiceCommandsLocal_${VERSION}_Installer.dmg"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "========================================================================"
echo -e "${BLUE}Voice Commands Local - Unified DMG Build Pipeline${NC}"
echo "========================================================================"
echo ""
echo -e "Version: ${YELLOW}${VERSION}${NC}"
echo ""

# Check if this version already exists
if [ -f "$BUILD_DIR/$DMG_NAME" ]; then
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: DMG for ${VERSION} already exists!${NC}"
    echo -e "${YELLOW}⚠️  Did you update MARKETING_VERSION in VoiceCommandsLocal/project.yml?${NC}"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 1
    fi
fi

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}ERROR: Xcode project not found at: $PROJECT_PATH${NC}"
    exit 1
fi

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Clean previous build
echo -e "${BLUE}Step 1/4: Cleaning previous build...${NC}"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme VoiceCommandsLocal \
    -configuration Release \
    clean \
    > /dev/null 2>&1

echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# Build Release version
echo -e "${BLUE}Step 2/4: Building Release version ${VERSION}...${NC}"
run_xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme VoiceCommandsLocal \
    -configuration Release \
    -derivedDataPath "$PROJECT_ROOT/.build" \
    CODE_SIGN_ENTITLEMENTS="VoiceCommandsLocal/VoiceCommandsLocal.entitlements" \
    MARKETING_VERSION="$NUMERIC_VERSION" \
    build

# Check if build succeeded
APP_PATH="$PROJECT_ROOT/.build/Build/Products/Release/VoiceCommandsLocal.app"
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}ERROR: Build failed - app not found${NC}"
    exit 1
fi

# Get app size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo -e "${GREEN}✓ Build succeeded (${APP_SIZE})${NC}"
echo ""

# Build DMG with installer/uninstaller
echo -e "${BLUE}Step 3/4: Creating installer packages...${NC}"
"$PROJECT_ROOT/installer/build-dmg.sh" "$VERSION" "$APP_PATH"

# Verify DMG was created
if [ ! -f "$BUILD_DIR/$DMG_NAME" ]; then
    echo -e "${RED}ERROR: DMG creation failed${NC}"
    exit 1
fi

# Get DMG size
DMG_SIZE=$(du -sh "$BUILD_DIR/$DMG_NAME" | cut -f1)
echo ""
echo -e "${BLUE}Step 4/4: Verifying DMG contents...${NC}"

# Mount DMG to verify contents
MOUNT_POINT="/Volumes/Voice Commands Local $VERSION"
hdiutil attach "$BUILD_DIR/$DMG_NAME" -mountpoint "$MOUNT_POINT" -quiet

# Check for required files
VERIFICATION_PASSED=true

if [ ! -f "$MOUNT_POINT/Install Voice Commands Local.pkg" ]; then
    echo -e "${RED}✗ Installer package missing${NC}"
    VERIFICATION_PASSED=false
else
    echo -e "${GREEN}✓ Installer package found${NC}"
    
    # Verify installer contains the app using Bill of Materials (no extraction needed)
    TEMP_VERIFY="$PROJECT_ROOT/.verify_temp"
    rm -rf "$TEMP_VERIFY"
    pkgutil --expand "$MOUNT_POINT/Install Voice Commands Local.pkg" "$TEMP_VERIFY"
    
    if lsbom "$TEMP_VERIFY/Bom" 2>/dev/null | grep -q "VoiceCommandsLocal.app/Contents/MacOS/VoiceCommandsLocal"; then
        echo -e "${GREEN}✓ App embedded in installer package${NC}"
    else
        echo -e "${RED}✗ App NOT found in installer package${NC}"
        VERIFICATION_PASSED=false
    fi
    
    rm -rf "$TEMP_VERIFY"
fi

if [ ! -d "$MOUNT_POINT/Uninstall Voice Commands Local.app" ]; then
    echo -e "${RED}✗ Uninstaller app missing${NC}"
    VERIFICATION_PASSED=false
else
    echo -e "${GREEN}✓ Uninstaller app found${NC}"
fi

if [ ! -f "$MOUNT_POINT/User Manual.md" ]; then
    echo -e "${RED}✗ User manual missing${NC}"
    VERIFICATION_PASSED=false
else
    echo -e "${GREEN}✓ User manual found${NC}"
fi

# Unmount DMG
hdiutil detach "$MOUNT_POINT" -quiet

# Summary
echo ""
echo "========================================================================"
if [ "$VERIFICATION_PASSED" = true ]; then
    echo -e "${GREEN}Build Complete! ✓${NC}"
else
    echo -e "${RED}Build Failed: DMG verification did not pass${NC}"
fi
echo "========================================================================"
echo -e "Version:     ${YELLOW}${VERSION}${NC}"
echo -e "App size:    ${YELLOW}${APP_SIZE}${NC}"
echo -e "DMG size:    ${YELLOW}${DMG_SIZE}${NC}"
echo -e "DMG file:    ${YELLOW}${DMG_NAME}${NC}"
echo -e "Location:    ${YELLOW}${BUILD_DIR}${NC}"
echo ""
echo -e "${BLUE}DMG Contents:${NC}"
echo "  • Install Voice Commands Local.pkg (contains app)"
echo "  • Uninstall Voice Commands Local.app"
echo "  • User Manual.md"
echo ""
echo -e "${BLUE}To test the installer:${NC}"
echo -e "  open \"$BUILD_DIR/$DMG_NAME\""
echo ""
echo -e "${BLUE}To open builds folder:${NC}"
echo -e "  open \"$BUILD_DIR\""
echo ""
echo -e "${YELLOW}REMINDER: Update docs/VERSIONS.md before distributing!${NC}"
echo ""

if [ "$VERIFICATION_PASSED" != true ]; then
    echo -e "${RED}ERROR: DMG verification failed${NC}" >&2
    exit 1
fi
