import AppKit
import MapKit

class MapSnapshotGenerator {
    
    func generateSnapshot(style: MapStyle, region: MapRegion, completion: @escaping (MKMapSnapshotter.Snapshot?) -> Void) {
        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }
        
        let size = screen.frame.size
        
        // Create coordinate region - wider for landscape screens
        let center = CLLocationCoordinate2D(latitude: region.lat, longitude: region.lon)
        let latSpan = region.span
        let lonSpan = region.span * (size.width / size.height)  // Adjust for screen aspect ratio
        let mapSpan = MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan)
        let mapRegion = MKCoordinateRegion(center: center, span: mapSpan)
        
        log("Map snapshot: center=(\(region.lat), \(region.lon)), span=(\(latSpan), \(lonSpan)), size=\(size)")
        
        // Configure map snapshot options
        let options = MKMapSnapshotter.Options()
        options.size = size
        options.region = mapRegion
        
        // Set map style (avoid flyover types which show 3D globe)
        switch style {
        case .satellite:
            let config = MKHybridMapConfiguration()
            config.pointOfInterestFilter = .excludingAll
            if #available(macOS 14.0, *) {
                options.preferredConfiguration = config
            }
        case .dark, .blackout:
            let config = MKStandardMapConfiguration()
            config.pointOfInterestFilter = .excludingAll
            if #available(macOS 14.0, *) {
                options.preferredConfiguration = config
            }
            // Force dark appearance regardless of system setting
            options.appearance = NSAppearance(named: .darkAqua)
        case .light:
            let config = MKStandardMapConfiguration()
            config.pointOfInterestFilter = .excludingAll
            if #available(macOS 14.0, *) {
                options.preferredConfiguration = config
            }
            // Force light appearance regardless of system setting
            options.appearance = NSAppearance(named: .aqua)
        }
        
        // Disable POI for cleaner map (fallback for older configs)
        options.pointOfInterestFilter = .excludingAll
        
        // Ensure we're showing a flat map, not 3D
        options.showsBuildings = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        
        snapshotter.start { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                log("ERROR: Map snapshot failed: \(error?.localizedDescription ?? "unknown")")
                completion(nil)
                return
            }
            completion(snapshot)
        }
    }
    
    func getMapRegion(for region: MapRegion) -> MKCoordinateRegion {
        guard let screen = NSScreen.main else {
            return MKCoordinateRegion()
        }
        
        let size = screen.frame.size
        let center = CLLocationCoordinate2D(latitude: region.lat, longitude: region.lon)
        let latSpan = region.span
        let lonSpan = region.span * (size.width / size.height)
        let mapSpan = MKCoordinateSpan(latitudeDelta: latSpan, longitudeDelta: lonSpan)
        return MKCoordinateRegion(center: center, span: mapSpan)
    }
}