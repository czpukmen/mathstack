#!/bin/bash

# Math Stack TestFlight Build Script
# Run this script from your project root directory

echo "🚀 Building Math Stack for TestFlight..."

# Set variables
SCHEME="Mathstack"
PROJECT_PATH="iOS/Mathstack/Mathstack.xcodeproj"
ARCHIVE_PATH="./build/Mathstack.xcarchive"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf ./build
mkdir -p ./build

# Create archive
echo "📦 Creating archive..."
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release

# Check if archive was successful
if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    echo "📤 Ready to upload to App Store Connect"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode Organizer"
    echo "2. Select your archive"
    echo "3. Click 'Distribute App' → 'App Store Connect' → 'Upload'"
    echo ""
    echo "Or use this command:"
    echo "xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath ./build/export -exportOptionsPlist ExportOptions.plist"
else
    echo "❌ Archive failed!"
    exit 1
fi 