import AppKit
import MapKit

class WallpaperManager {
    // MARK: - Properties
    var mapStyle: MapStyle {
        didSet { Preferences.mapStyle = mapStyle }
    }
    var regionIndex: Int {
        didSet { Preferences.regionIndex = regionIndex }
    }
    var region: MapRegion {
        get { MapRegion.all[regionIndex] }
        set { regionIndex = MapRegion.all.firstIndex(where: { $0.name == newValue.name }) ?? 0 }
    }
    var autoRefreshEnabled: Bool {
        didSet { Preferences.autoRefreshEnabled = autoRefreshEnabled }
    }
    var radarLayerEnabled: Bool {
        didSet { Preferences.radarLayerEnabled = radarLayerEnabled }
    }
    var satelliteLayerEnabled: Bool {
        didSet { Preferences.satelliteLayerEnabled = satelliteLayerEnabled }
    }
    var refreshInterval: TimeInterval {
        didSet {
            Preferences.refreshInterval = refreshInterval
            startAutoRefresh()
        }
    }
    
    // MARK: - Callbacks
    var onGenerationStarted: (() -> Void)?
    var onGenerationEnded: (() -> Void)?
    var onWallpaperSet: (() -> Void)?
    
    // MARK: - Private Properties
    private var refreshTimer: Timer?
    private var isGenerating = false
    private var pendingRefresh = false
    private var currentWallpaperPath: String?
    
    // MARK: - Components
    private let weatherFetcher = WeatherDataFetcher()
    private let tileRenderer = TileRenderer()
    private let snapshotGenerator = MapSnapshotGenerator()
    private let imageCompositor = ImageCompositor()
    private let fileManager = WallpaperFileManager()
    private let wallpaperSetter = WallpaperSetter()
    
    // MARK: - Initialization
    init() {
        // Load saved preferences
        self.mapStyle = Preferences.mapStyle
        self.regionIndex = Preferences.regionIndex
        self.autoRefreshEnabled = Preferences.autoRefreshEnabled
        self.refreshInterval = Preferences.refreshInterval
        self.radarLayerEnabled = Preferences.radarLayerEnabled
        self.satelliteLayerEnabled = Preferences.satelliteLayerEnabled
        
        // Set up wallpaper setter callback
        wallpaperSetter.onWallpaperSet = { [weak self] in
            self?.onWallpaperSet?()
        }
        
        startAutoRefresh()
    }
    
    // MARK: - Public Methods
    func startListening() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        log("Started listening for space changes")
    }
    
    @objc func spaceDidChange(_ notification: Notification) {
        log("Space changed - re-applying wallpaper")
        if let path = currentWallpaperPath {
            wallpaperSetter.applyWallpaper(path: path)
        }
    }
    
    func startAutoRefresh() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.refreshTimer?.invalidate()
            let timer = Timer(timeInterval: self.refreshInterval, repeats: true) { [weak self] _ in
                if self?.autoRefreshEnabled == true {
                    let interval = Int(self?.refreshInterval ?? 0)
                    let intervalStr = interval < 60 ? "\(interval) sec" : "\(interval / 60) min"
                    log("Auto-refreshing wallpaper (interval: \(intervalStr))...")
                    self?.generateAndSetWallpaper()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            self.refreshTimer = timer
            log("Timer scheduled with interval: \(Int(self.refreshInterval)) seconds")
        }
    }
    
    func generateAndSetWallpaper() {
        guard !isGenerating else {
            log("Already generating, queuing refresh...")
            pendingRefresh = true
            return
        }
        isGenerating = true
        pendingRefresh = false
        onGenerationStarted?()
        
        let styleToGenerate = self.mapStyle
        let regionToGenerate = self.region
        let radarEnabled = self.radarLayerEnabled
        let satelliteEnabled = self.satelliteLayerEnabled
        
        log("Generating wallpaper (style: \(styleToGenerate.rawValue), region: \(regionToGenerate.name), radar: \(radarEnabled), satellite: \(satelliteEnabled))...")
        
        // Fetch weather layer data from RainViewer API
        weatherFetcher.fetchWeatherLayers { [weak self] layers in
            guard let self = self else { return }
            
            if let radarPath = layers.radarPath {
                log("Got radar path: \(radarPath)")
            }
            if let satellitePath = layers.satellitePath {
                log("Got satellite path: \(satellitePath)")
            }
            
            // Only use paths for enabled layers
            let activeLayers = WeatherLayers(
                radarPath: radarEnabled ? layers.radarPath : nil,
                satellitePath: satelliteEnabled ? layers.satellitePath : nil
            )
            
            // Generate the map snapshot on main thread (required for MapKit)
            DispatchQueue.main.async {
                self.generateMapAndComposite(style: styleToGenerate, region: regionToGenerate, layers: activeLayers) { [weak self] image in
                    guard let self = self else { return }
                    
                    defer {
                        self.isGenerating = false
                        self.onGenerationEnded?()
                        if self.pendingRefresh {
                            log("Processing pending refresh...")
                            self.generateAndSetWallpaper()
                        }
                    }
                    
                    guard let image = image else {
                        log("ERROR: Failed to generate map")
                        return
                    }
                    
                    // Save and set wallpaper
                    if let path = self.fileManager.saveWallpaper(image: image) {
                        self.currentWallpaperPath = path
                        self.wallpaperSetter.applyWallpaper(path: path)
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func generateMapAndComposite(style: MapStyle, region: MapRegion, layers: WeatherLayers, completion: @escaping (NSImage?) -> Void) {
        // Generate base map snapshot
        snapshotGenerator.generateSnapshot(style: style, region: region) { [weak self] snapshot in
            guard let self = self, let snapshot = snapshot else {
                completion(nil)
                return
            }
            
            // Check if we need to overlay weather layers
            if layers.satellitePath != nil || layers.radarPath != nil {
                let mapRegion = self.snapshotGenerator.getMapRegion(for: region)
                let tiles = self.tileRenderer.calculateTilesForRegion(mapRegion: mapRegion, size: snapshot.image.size)
                
                log("Fetching \(tiles.count) tiles for weather overlay...")
                
                // Fetch weather tiles
                self.weatherFetcher.fetchWeatherTiles(tiles: tiles, layers: layers) { satelliteTiles, radarTiles in
                    // Composite weather layers onto map
                    self.imageCompositor.compositeWeatherLayers(
                        on: snapshot,
                        satelliteTiles: satelliteTiles,
                        radarTiles: radarTiles,
                        style: style,
                        completion: completion
                    )
                }
            } else if style == .blackout {
                // Apply blackout filter even without weather layers
                self.imageCompositor.applyBlackoutFilter(to: snapshot.image, completion: completion)
            } else {
                completion(snapshot.image)
            }
        }
    }
}