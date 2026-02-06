#!/bin/bash
set -e

echo "Installing Hemisphere..."

# Check for Xcode command line tools
if ! xcode-select -p &> /dev/null; then
    echo "Error: Xcode Command Line Tools required. Install with: xcode-select --install"
    exit 1
fi

# Create temp directory
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Clone and build
git clone --depth 1 https://github.com/pdsullivan/hemisphere.git
cd hemisphere/Hemisphere
swift build -c release

# Copy to Applications
APP_PATH="$HOME/Applications/Hemisphere"
mkdir -p "$HOME/Applications"
rm -rf "$APP_PATH"
cp .build/release/Hemisphere "$APP_PATH"

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "Installed to ~/Applications/Hemisphere"
echo ""
echo "To run: ~/Applications/Hemisphere"
echo "To run at login: Add to System Settings > General > Login Items"
