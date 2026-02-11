#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HEMISPHERE_DIR="$PROJECT_ROOT/Hemisphere"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="Hemisphere"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building Hemisphere..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the executable
cd "$HEMISPHERE_DIR"
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/release/Hemisphere" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$HEMISPHERE_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy app icon if it exists
if [ -f "$HEMISPHERE_DIR/Resources/AppIcon.icns" ]; then
    cp "$HEMISPHERE_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo ""
echo "To run: open $APP_BUNDLE"
