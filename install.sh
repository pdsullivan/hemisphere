#!/bin/bash
set -e

APP_NAME="Hemisphere"
BUNDLE_ID="com.hemisphere.app"
APP_DEST="$HOME/Applications/$APP_NAME.app"
LAUNCH_AGENT_SRC="Resources/com.hemisphere.app.plist"
LAUNCH_AGENT_DEST="$HOME/Library/LaunchAgents/com.hemisphere.app.plist"

echo "Installing Hemisphere..."
echo ""

# Check for Xcode command line tools
if ! xcode-select -p &> /dev/null; then
    echo "Error: Xcode Command Line Tools required. Install with: xcode-select --install"
    exit 1
fi

# Create temp directory
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Clone and build
echo "Downloading..."
git clone --depth 1 https://github.com/pdsullivan/hemisphere.git
cd hemisphere

# Build the app bundle
echo "Building..."
./scripts/build-app.sh

# Stop existing instance if running
if pgrep -x "Hemisphere" > /dev/null; then
    echo "Stopping existing Hemisphere..."
    pkill -x "Hemisphere" || true
    sleep 1
fi

# Unload existing LaunchAgent if present
if [ -f "$LAUNCH_AGENT_DEST" ]; then
    launchctl unload "$LAUNCH_AGENT_DEST" 2>/dev/null || true
fi

# Copy app to Applications
echo "Installing app..."
mkdir -p "$HOME/Applications"
rm -rf "$APP_DEST"
cp -R build/$APP_NAME.app "$APP_DEST"

# Install LaunchAgent for auto-start
echo "Setting up auto-start..."
mkdir -p "$HOME/Library/LaunchAgents"

# Update LaunchAgent plist to use user's Applications folder
cat > "$LAUNCH_AGENT_DEST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$BUNDLE_ID</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_DEST/Contents/MacOS/Hemisphere</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl load "$LAUNCH_AGENT_DEST"

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "✓ Installed to $APP_DEST"
echo "✓ Will start automatically on login"
echo ""

# Offer to start now
read -p "Start Hemisphere now? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    open "$APP_DEST"
    echo "Started! Look for the cloud icon in your menu bar."
fi
