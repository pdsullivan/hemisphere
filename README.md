# Hemisphere

a macos menu bar app that sets your desktop wallpaper to a live weather radar map.

![Hemisphere Screenshot](screenshot.png)

## features

- live weather radar overlay from rainviewer api
- works across all macos spaces
- map styles: satellite, dark, black out, and light
- region presets: continental us, northeast, southeast, midwest, and more
- configurable refresh intervals (1 min to 1 hour)
- settings persist between launches

## requirements

- macos 13+
- xcode command line tools

## installation

run this in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/pdsullivan/hemisphere/main/install.sh | bash
```

then run the app:

```bash
~/Applications/Hemisphere
```

on first run, macos will ask for permission to control system events. click ok - this is needed to set wallpaper across all spaces.

### keeping it running

add `~/Applications/Hemisphere` to your login items in system settings > general > login items.

## usage

click the cloud icon in your menu bar to:

- **refresh wallpaper** - generate a new radar image
- **map style** - switch between satellite, dark, black out, or light
- **region** - choose continental us or zoom into a specific region
- **show radar** - toggle radar overlay on/off
- **refresh interval** - set how often the wallpaper updates

## development

if you want to hack on hemisphere:

```bash
git clone https://github.com/pdsullivan/hemisphere.git
cd hemisphere/Hemisphere
swift build
.build/debug/Hemisphere
```

### project structure

```
hemisphere/
├── Hemisphere/
│   ├── Package.swift
│   └── Sources/
│       ├── AppDelegate.swift      # menu bar setup
│       ├── HemisphereApp.swift    # app entry point
│       ├── LoadingOverlay.swift   # loading spinner
│       ├── Models.swift           # map styles and regions
│       ├── Preferences.swift      # userdefaults persistence
│       ├── RainViewer.swift       # weather api types
│       ├── Utilities.swift        # logging
│       └── WallpaperManager.swift # map generation and wallpaper setting
└── install.sh
```

### how it works

1. `MKMapSnapshotter` renders a map of the selected region
2. rainviewer api provides real-time radar tile paths
3. radar tiles are fetched and composited onto the map
4. applescript sets the wallpaper across all spaces

## troubleshooting

**wallpaper not updating?**
- check `~/hemisphere.log` for errors
- make sure you granted system events permission

**"can't be opened because it's from an unidentified developer"?**
- right-click the app and select open, then click open in the dialog

## license

MIT
