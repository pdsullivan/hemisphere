import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var wallpaperManager: WallpaperManager?

    // Menu items
    var lastUpdatedMenuItem: NSMenuItem?
    var satelliteMenuItem: NSMenuItem?
    var darkMenuItem: NSMenuItem?
    var blackoutMenuItem: NSMenuItem?
    var lightMenuItem: NSMenuItem?

    // Refresh interval menu
    var refreshIntervalMenuItems: [NSMenuItem] = []
    let refreshIntervalOptions: [(title: String, seconds: Int)] = [
        ("1 minute", 60),
        ("5 minutes", 300),
        ("10 minutes", 600),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600)
    ]

    // Region menu
    var regionMenuItems: [NSMenuItem] = []

    // Weather layer menu items
    var radarLayerMenuItem: NSMenuItem?
    
    // Login item
    var startAtLoginMenuItem: NSMenuItem?
    let launchAgentPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/com.hemisphere.app.plist")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cloud.sun.rain", accessibilityDescription: "Hemisphere")
        }

        // Create menu
        let menu = NSMenu()

        lastUpdatedMenuItem = NSMenuItem(title: "Last updated: --", action: nil, keyEquivalent: "")
        lastUpdatedMenuItem?.isEnabled = false
        menu.addItem(lastUpdatedMenuItem!)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Refresh Wallpaper", action: #selector(refreshWallpaper), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())

        let mapStyleMenu = NSMenu()

        satelliteMenuItem = NSMenuItem(title: "Satellite", action: #selector(setMapStyleSatellite), keyEquivalent: "")
        satelliteMenuItem?.state = .on  // Default selected
        mapStyleMenu.addItem(satelliteMenuItem!)

        darkMenuItem = NSMenuItem(title: "Dark", action: #selector(setMapStyleDark), keyEquivalent: "")
        mapStyleMenu.addItem(darkMenuItem!)

        blackoutMenuItem = NSMenuItem(title: "Black Out", action: #selector(setMapStyleBlackout), keyEquivalent: "")
        mapStyleMenu.addItem(blackoutMenuItem!)

        lightMenuItem = NSMenuItem(title: "Light", action: #selector(setMapStyleLight), keyEquivalent: "")
        mapStyleMenu.addItem(lightMenuItem!)

        let mapStyleItem = NSMenuItem(title: "Map Style", action: nil, keyEquivalent: "")
        mapStyleItem.submenu = mapStyleMenu
        menu.addItem(mapStyleItem)

        // Region submenu
        let regionMenu = NSMenu()
        for (index, region) in MapRegion.all.enumerated() {
            let item = NSMenuItem(title: region.name, action: #selector(setRegion(_:)), keyEquivalent: "")
            item.tag = index
            item.state = index == 0 ? .on : .off  // Default: Continental US
            regionMenu.addItem(item)
            regionMenuItems.append(item)
        }

        let regionItem = NSMenuItem(title: "Region", action: nil, keyEquivalent: "")
        regionItem.submenu = regionMenu
        menu.addItem(regionItem)

        // Radar layer toggle
        radarLayerMenuItem = NSMenuItem(title: "Show Radar", action: #selector(toggleRadarLayer(_:)), keyEquivalent: "")
        radarLayerMenuItem?.state = .on
        menu.addItem(radarLayerMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // Auto-refresh toggle
        let autoRefreshItem = NSMenuItem(title: "Auto-Refresh", action: #selector(toggleAutoRefresh), keyEquivalent: "")
        autoRefreshItem.state = .on
        menu.addItem(autoRefreshItem)

        // Refresh interval submenu
        let refreshIntervalMenu = NSMenu()
        for option in refreshIntervalOptions {
            let item = NSMenuItem(title: option.title, action: #selector(setRefreshInterval(_:)), keyEquivalent: "")
            item.tag = option.seconds
            item.state = option.seconds == 600 ? .on : .off  // Default 10 minutes
            refreshIntervalMenu.addItem(item)
            refreshIntervalMenuItems.append(item)
        }

        let refreshIntervalItem = NSMenuItem(title: "Refresh Interval", action: nil, keyEquivalent: "")
        refreshIntervalItem.submenu = refreshIntervalMenu
        menu.addItem(refreshIntervalItem)

        menu.addItem(NSMenuItem.separator())
        
        // Start at Login toggle
        startAtLoginMenuItem = NSMenuItem(title: "Start at Login", action: #selector(toggleStartAtLogin(_:)), keyEquivalent: "")
        startAtLoginMenuItem?.state = isLaunchAgentInstalled() ? .on : .off
        menu.addItem(startAtLoginMenuItem!)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Uninstall...", action: #selector(uninstallApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu

        // Initialize wallpaper manager
        wallpaperManager = WallpaperManager()
        wallpaperManager?.onGenerationStarted = { [weak self] in
            self?.showLoadingState()
        }
        wallpaperManager?.onGenerationEnded = { [weak self] in
            self?.hideLoadingState()
        }
        wallpaperManager?.onWallpaperSet = { [weak self] in
            self?.updateLastUpdatedTime()
        }
        wallpaperManager?.startListening()

        // Update menu checkmarks to reflect loaded preferences
        updateAllMenuCheckmarks()

        // Initial wallpaper set
        refreshWallpaper()
    }

    func updateAllMenuCheckmarks() {
        guard let wm = wallpaperManager else { return }

        // Map style
        updateStyleCheckmarks()

        // Region
        for item in regionMenuItems {
            item.state = item.tag == wm.regionIndex ? .on : .off
        }

        // Refresh interval
        let interval = Int(wm.refreshInterval)
        for item in refreshIntervalMenuItems {
            item.state = item.tag == interval ? .on : .off
        }

        // Auto-refresh - find the menu item
        if let menu = statusItem?.menu {
            for item in menu.items where item.title == "Auto-Refresh" {
                item.state = wm.autoRefreshEnabled ? .on : .off
            }
        }

        // Weather layers
        radarLayerMenuItem?.state = wm.radarLayerEnabled ? .on : .off
    }

    func updateLastUpdatedTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let timeString = formatter.string(from: Date())
        lastUpdatedMenuItem?.title = "Last updated: \(timeString)"
    }

    func showLoadingState() {
        DispatchQueue.main.async {
            self.lastUpdatedMenuItem?.title = "Generating..."
            LoadingOverlay.shared.show()
        }
    }

    func hideLoadingState() {
        DispatchQueue.main.async {
            LoadingOverlay.shared.hide()
        }
    }

    @objc func refreshWallpaper() {
        wallpaperManager?.generateAndSetWallpaper()
    }

    @objc func setMapStyleSatellite() {
        wallpaperManager?.mapStyle = .satellite
        updateStyleCheckmarks()
        refreshWallpaper()
    }

    @objc func setMapStyleDark() {
        wallpaperManager?.mapStyle = .dark
        updateStyleCheckmarks()
        refreshWallpaper()
    }

    @objc func setMapStyleLight() {
        wallpaperManager?.mapStyle = .light
        updateStyleCheckmarks()
        refreshWallpaper()
    }

    @objc func setMapStyleBlackout() {
        wallpaperManager?.mapStyle = .blackout
        updateStyleCheckmarks()
        refreshWallpaper()
    }

    func updateStyleCheckmarks() {
        satelliteMenuItem?.state = wallpaperManager?.mapStyle == .satellite ? .on : .off
        darkMenuItem?.state = wallpaperManager?.mapStyle == .dark ? .on : .off
        blackoutMenuItem?.state = wallpaperManager?.mapStyle == .blackout ? .on : .off
        lightMenuItem?.state = wallpaperManager?.mapStyle == .light ? .on : .off
    }

    @objc func toggleAutoRefresh(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        wallpaperManager?.autoRefreshEnabled = sender.state == .on
    }

    @objc func setRefreshInterval(_ sender: NSMenuItem) {
        let seconds = sender.tag
        wallpaperManager?.refreshInterval = TimeInterval(seconds)

        // Update checkmarks
        for item in refreshIntervalMenuItems {
            item.state = item.tag == seconds ? .on : .off
        }
    }

    @objc func setRegion(_ sender: NSMenuItem) {
        let index = sender.tag
        wallpaperManager?.regionIndex = index

        // Update checkmarks
        for item in regionMenuItems {
            item.state = item.tag == index ? .on : .off
        }

        refreshWallpaper()
    }

    @objc func toggleRadarLayer(_ sender: NSMenuItem) {
        sender.state = sender.state == .on ? .off : .on
        wallpaperManager?.radarLayerEnabled = sender.state == .on
        refreshWallpaper()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Launch Agent Management
    
    func isLaunchAgentInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: launchAgentPath.path)
    }
    
    @objc func toggleStartAtLogin(_ sender: NSMenuItem) {
        if isLaunchAgentInstalled() {
            removeLaunchAgent()
            sender.state = .off
        } else {
            installLaunchAgent()
            sender.state = .on
        }
    }
    
    func installLaunchAgent() {
        guard let appPath = Bundle.main.bundlePath as String? else { return }
        let executablePath = "\(appPath)/Contents/MacOS/Hemisphere"
        
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.hemisphere.app</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """
        
        do {
            let launchAgentsDir = launchAgentPath.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
            try plistContent.write(to: launchAgentPath, atomically: true, encoding: .utf8)
            
            // Load the agent
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["load", launchAgentPath.path]
            try task.run()
            task.waitUntilExit()
            
            log("LaunchAgent installed")
        } catch {
            log("Failed to install LaunchAgent: \(error)")
        }
    }
    
    func removeLaunchAgent() {
        do {
            // Unload the agent first
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["unload", launchAgentPath.path]
            try task.run()
            task.waitUntilExit()
            
            // Remove the file
            try FileManager.default.removeItem(at: launchAgentPath)
            log("LaunchAgent removed")
        } catch {
            log("Failed to remove LaunchAgent: \(error)")
        }
    }
    
    @objc func uninstallApp() {
        let alert = NSAlert()
        alert.messageText = "Uninstall Hemisphere?"
        alert.informativeText = "This will remove the app from starting at login. You can delete the app manually from your Applications folder."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            removeLaunchAgent()
            
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Uninstalled"
            confirmAlert.informativeText = "Hemisphere will no longer start at login. The app will now quit."
            confirmAlert.alertStyle = .informational
            confirmAlert.addButton(withTitle: "OK")
            confirmAlert.runModal()
            
            NSApplication.shared.terminate(nil)
        }
    }
}
