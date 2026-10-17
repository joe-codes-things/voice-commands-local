#!/bin/bash

#
# Build and run Voice Commands Local
# Builds the Swift app and launches it directly - no Xcode interaction needed
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/version.sh"
VERSION="$(read_project_version "$PROJECT_ROOT")"
NUMERIC_VERSION="${VERSION#v}"
PROJECT_PATH="$PROJECT_ROOT/VoiceCommandsLocal/VoiceCommandsLocal.xcodeproj"
APP_PATH="$PROJECT_ROOT/.build/Build/Products/Debug/VoiceCommandsLocal.app"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "========================================================================"
echo -e "${BLUE}Voice Commands Local${NC}"
echo "========================================================================"
echo ""

# Kill any running instances of the app
echo -e "${BLUE}Checking for running instances...${NC}"
if pgrep -x "VoiceCommandsLocal" > /dev/null; then
    echo -e "${BLUE}Terminating existing app instance...${NC}"
    pkill -x "VoiceCommandsLocal"
    sleep 0.5
    echo -e "${GREEN}App terminated${NC}"
else
    echo -e "${GREEN}No running instances found${NC}"
fi

# Check if Xcode project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}ERROR: Xcode project not found at: $PROJECT_PATH${NC}"
    exit 1
fi

# Build
echo -e "${BLUE}Building app...${NC}"
run_xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme VoiceCommandsLocal \
    -configuration Debug \
    -derivedDataPath "$PROJECT_ROOT/.build" \
    MARKETING_VERSION="$NUMERIC_VERSION" \
    build

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}ERROR: Build failed - app not found${NC}"
    exit 1
fi

echo -e "${GREEN}Build succeeded${NC}"
echo -e "${GREEN}Launching app...${NC}"
echo ""

open "$APP_PATH"
