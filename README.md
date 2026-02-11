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

## installation

### option 1: download dmg

1. download `Hemisphere-Installer.dmg` from the [latest release](https://github.com/pdsullivan/hemisphere/releases/latest)
2. open the dmg and drag `Hemisphere.app` to Applications
3. right-click and select "open" to bypass gatekeeper
4. grant system events permission when prompted
5. enable "start at login" from the menu bar icon

### option 2: install script

requires xcode command line tools (`xcode-select --install`)

```bash
curl -fsSL https://raw.githubusercontent.com/pdsullivan/hemisphere/main/install.sh | bash
```

this will build, install, and set up hemisphere to start automatically on login.

on first run, macos will ask for permission to control system events. click ok - this is needed to set wallpaper across all spaces.

## usage

click the cloud icon in your menu bar to:

- **refresh wallpaper** - generate a new radar image
- **map style** - switch between satellite, dark, black out, or light
- **region** - choose continental us or zoom into a specific region
- **show radar** - toggle radar overlay on/off
- **refresh interval** - set how often the wallpaper updates
- **start at login** - toggle auto-start on login
- **uninstall** - remove auto-start and quit

## development

if you want to hack on hemisphere:

```bash
git clone https://github.com/pdsullivan/hemisphere.git
cd hemisphere
./scripts/build-dmg.sh
```

this builds the app and opens the dmg installer.

to build just the app bundle:

```bash
./scripts/build-app.sh
open build/Hemisphere.app
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
