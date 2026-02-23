#!/bin/bash
# Build and package ScrcpyConnect.app
set -e
cd "$(dirname "$0")"

echo "Building ScrcpyConnect..."
swift build -c release

APP_DIR="ScrcpyConnect.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/release/ScrcpyConnect "$APP_DIR/Contents/MacOS/"
cp Sources/Info.plist "$APP_DIR/Contents/Info.plist"

# Copy app icon if it exists
if [ -f Resources/AppIcon.icns ]; then
    cp Resources/AppIcon.icns "$APP_DIR/Contents/Resources/"
    echo "   Icon: AppIcon.icns included"
else
    echo "⚠️  No AppIcon.icns found in Resources/ — app will use default icon"
fi

echo "✅ Built: $(pwd)/$APP_DIR"
echo "   Run:  open $APP_DIR"
