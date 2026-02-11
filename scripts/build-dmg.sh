#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
APP_NAME="Hemisphere"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="Hemisphere-Installer"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"
DMG_TEMP="$BUILD_DIR/dmg-temp"

# Build the app first
echo "Building app..."
"$SCRIPT_DIR/build-app.sh"

# Check app was built
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    exit 1
fi

echo ""
echo "Creating DMG..."

# Clean up any previous DMG build
rm -rf "$DMG_TEMP"
rm -f "$DMG_PATH"

# Create temp directory for DMG contents
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# Create symlink to Applications
ln -s /Applications "$DMG_TEMP/Applications"

# Create a simple README
cat > "$DMG_TEMP/README.txt" << 'EOF'
Hemisphere Installation
=======================

1. Drag Hemisphere.app to the Applications folder
2. Open Hemisphere from Applications
3. Right-click and select "Open" if you see a security warning
4. Grant System Events permission when prompted

To start automatically on login:
- Open Hemisphere
- Click the menu bar icon
- Select "Start at Login"

To uninstall:
- Open Hemisphere menu
- Select "Uninstall..."
EOF

# Create the DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_TEMP"

echo ""
echo "✓ Created: $DMG_PATH"
echo ""
echo "The DMG contains:"
echo "  - Hemisphere.app"
echo "  - Applications shortcut (for drag-to-install)"
echo "  - README.txt"
echo ""
echo "Opening installer..."
open "$DMG_PATH"
