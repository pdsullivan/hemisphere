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

### 1. Clone and install dependencies

```bash
git clone https://github.com/pdsullivan/hemisphere.git
cd hemisphere
npm install
```

### 2. Build the Swift app

```bash
cd Hemisphere
swift build
cd ..
```

### 3. Run from the project root

```bash
./Hemisphere/.build/debug/Hemisphere
```

**Important:** Run from the project root directory (not from inside `Hemisphere/`) so the app can find `generate.js` and `map.html`.

### 4. Grant permissions

On first run, macOS will ask for permission to control System Events. Click **OK** — this is needed to set wallpaper across all Spaces.

### Keeping it running

To run Hemisphere in the background:

```bash
nohup ./Hemisphere/.build/debug/Hemisphere &
```

Or add it to your Login Items in System Settings > General > Login Items.

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

## Troubleshooting

**Wallpaper not updating?**
- Check `~/hemisphere.log` for errors
- Make sure you granted System Events permission
- Verify Node.js is installed: `node --version`

**Script not found error?**
- Run from the project root directory, not from `Hemisphere/`
- Or set `HEMISPHERE_SCRIPTS_DIR` to the full path containing `generate.js`

**Blank or partial wallpaper?**
- The map tiles may still be loading. Try Refresh Wallpaper again.
- Check your internet connection

## License

MIT
