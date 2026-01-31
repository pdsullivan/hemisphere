# Hemisphere

A macOS menu bar app that sets your desktop wallpaper to a live weather radar map.

![Hemisphere Screenshot](screenshot.png)

## Features

- Live weather radar overlay from RainViewer API
- Works across all macOS Spaces
- Three map styles: Satellite, Dark, and Light
- Auto-refreshes every 10 minutes
- Menu bar app with quick access to settings

## Requirements

- macOS 13+
- Node.js 18+
- npm

## Installation

```bash
# Clone the repo
git clone https://github.com/pdsullivan/hemisphere.git
cd hemisphere

# Install Node dependencies
npm install

# Build the Swift app
cd Hemisphere
swift build

# Run
.build/debug/Hemisphere
```

## Usage

Once running, click the cloud icon in your menu bar to:

- **Refresh Wallpaper** - Generate a new radar image
- **Map Style** - Switch between Satellite, Dark, or Light
- **Auto-Refresh** - Toggle automatic updates every 10 minutes

The app will automatically set the wallpaper across all your Spaces.

## How It Works

1. **Node.js + Puppeteer** renders a Leaflet.js map with radar overlay
2. **RainViewer API** provides real-time weather radar data
3. **Swift menu bar app** manages the lifecycle and settings
4. **AppleScript** sets the wallpaper across all Spaces

## Configuration

Set `HEMISPHERE_SCRIPTS_DIR` environment variable to customize the scripts location:

```bash
export HEMISPHERE_SCRIPTS_DIR=/path/to/hemisphere
```

## License

MIT
