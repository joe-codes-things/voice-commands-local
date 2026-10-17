#!/bin/bash

#
# Build Voice Commands Local for distribution
# Creates optimized Release build and copies to builds folder
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

# Check if this version already exists
if [ -d "$BUILD_DIR/VoiceCommandsLocal_${VERSION}.app" ]; then
    echo ""
    echo "⚠️  WARNING: Build for ${VERSION} already exists!"
    echo "⚠️  Did you update MARKETING_VERSION in VoiceCommandsLocal/project.yml?"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled."
        exit 1
    fi
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "========================================================================"
echo -e "${BLUE}Voice Commands Local - Build Pipeline${NC}"
echo "========================================================================"
echo ""

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}ERROR: Xcode project not found at: $PROJECT_PATH${NC}"
    exit 1
fi

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Clean previous build
echo -e "${BLUE}Cleaning previous build...${NC}"
xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme VoiceCommandsLocal \
    -configuration Release \
    clean \
    > /dev/null 2>&1

echo -e "${GREEN}Clean complete${NC}"

# Build Release version with version number
echo -e "${BLUE}Building Release version ${VERSION}...${NC}"
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

echo -e "${GREEN}Build succeeded${NC}"

# Get app size
APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
echo -e "${BLUE}App size: ${APP_SIZE}${NC}"

# Create build name
BUILD_NAME="VoiceCommandsLocal_${VERSION}.app"

# Copy to builds directory
echo -e "${BLUE}Copying to builds directory...${NC}"
rm -rf "$BUILD_DIR/$BUILD_NAME"
cp -R "$APP_PATH" "$BUILD_DIR/$BUILD_NAME"

echo -e "${GREEN}Build saved: ${BUILD_NAME}${NC}"
echo -e "${GREEN}   Location: $BUILD_DIR${NC}"

# Summary
echo ""
echo "========================================================================"
echo -e "${GREEN}Build Complete!${NC}"
echo "========================================================================"
echo -e "Version:     ${YELLOW}${VERSION}${NC}"
echo -e "App size:    ${YELLOW}${APP_SIZE}${NC}"
echo -e "Build:       ${YELLOW}${BUILD_NAME}${NC}"
echo -e "Location:    ${YELLOW}${BUILD_DIR}${NC}"
echo ""
echo -e "${BLUE}To run this build:${NC}"
echo -e "  open \"$BUILD_DIR/$BUILD_NAME\""
echo ""
echo -e "${BLUE}To open builds folder:${NC}"
echo -e "  open \"$BUILD_DIR\""
echo ""
echo -e "${YELLOW}REMINDER: Update docs/VERSIONS.md before distributing!${NC}"
echo ""
