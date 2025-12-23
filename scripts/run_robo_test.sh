#!/bin/bash

# ==============================================================================
# 🤖 Odyssey - Run Firebase Robo Test
# ==============================================================================
# Builds the app and runs a Robo test on Firebase Test Lab
# ==============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Robo Test Automation...${NC}"

# 1. Ensure APIs are enabled (fast check)
echo -e "${BLUE}📦 Checking APIs...${NC}"
gcloud services enable testing.googleapis.com toolresults.googleapis.com

# 2. Build the APK
echo -e "${BLUE}🔨 Building Debug APK...${NC}"
flutter build apk --debug

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi

APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"

if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}❌ APK not found at $APK_PATH${NC}"
    exit 1
fi

# 3. Run Robo Test
echo -e "${BLUE}🤖 Sending to Firebase Test Lab...${NC}"
echo "   Device: Pixel 6 (oriole), Android 13 (API 33)"
echo "   Type: Robo"

gcloud firebase test android run \
  --app "$APK_PATH" \
  --type robo \
  --device model=oriole,version=33 \
  --timeout 300s

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Test run started/completed successfully!${NC}"
    echo -e "${GREEN}📹 Check the link above for screenshots and videos.${NC}"
else
    echo -e "${RED}❌ Test run failed.${NC}"
fi
