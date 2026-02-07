import Foundation
import MapKit

class TileRenderer {
    
    func calculateTilesForRegion(mapRegion: MKCoordinateRegion, size: CGSize, minZoom: Int = 4) -> [(x: Int, y: Int, z: Int)] {
        let latSpan = mapRegion.span.latitudeDelta
        
        // Determine appropriate zoom level based on latitude span
        // Increased zoom levels for better resolution
        var z: Int
        if latSpan >= 30 {
            z = 5  // was 4
        } else if latSpan >= 15 {
            z = 6  // was 5
        } else if latSpan >= 8 {
            z = 7  // was 6
        } else if latSpan >= 4 {
            z = 8  // was 7
        } else {
            z = 9  // was 8
        }
        
        // Ensure minimum zoom level
        z = max(z, minZoom)
        
        // Calculate tile coordinates for the region bounds with a small buffer
        let buffer = 0.05  // 5% buffer to ensure full coverage
        let minLat = mapRegion.center.latitude - mapRegion.span.latitudeDelta / 2 * (1 + buffer)
        let maxLat = mapRegion.center.latitude + mapRegion.span.latitudeDelta / 2 * (1 + buffer)
        let minLon = mapRegion.center.longitude - mapRegion.span.longitudeDelta / 2 * (1 + buffer)
        let maxLon = mapRegion.center.longitude + mapRegion.span.longitudeDelta / 2 * (1 + buffer)
        
        let minTile = latLonToTile(lat: maxLat, lon: minLon, zoom: z)
        let maxTile = latLonToTile(lat: minLat, lon: maxLon, zoom: z)
        
        var tiles: [(x: Int, y: Int, z: Int)] = []
        for x in minTile.x...maxTile.x {
            for y in minTile.y...maxTile.y {
                tiles.append((x, y, z))
            }
        }
        return tiles
    }
    
    private func latLonToTile(lat: Double, lon: Double, zoom: Int) -> (x: Int, y: Int) {
        let n = pow(2.0, Double(zoom))
        let x = Int((lon + 180.0) / 360.0 * n)
        let latRad = lat * .pi / 180.0
        let y = Int((1.0 - asinh(tan(latRad)) / .pi) / 2.0 * n)
        return (x, y)
    }
    
    func tileToRect(tile: (x: Int, y: Int, z: Int), mapRegion: MKCoordinateRegion, size: CGSize) -> NSRect {
        let n = pow(2.0, Double(tile.z))
        
        // Tile bounds in lon/lat
        let tileLonMin = Double(tile.x) / n * 360.0 - 180.0
        let tileLonMax = Double(tile.x + 1) / n * 360.0 - 180.0
        let tileLatMax = atan(sinh(.pi * (1 - 2 * Double(tile.y) / n))) * 180.0 / .pi
        let tileLatMin = atan(sinh(.pi * (1 - 2 * Double(tile.y + 1) / n))) * 180.0 / .pi
        
        // Region bounds
        let regionLatMin = mapRegion.center.latitude - mapRegion.span.latitudeDelta / 2
        let regionLatMax = mapRegion.center.latitude + mapRegion.span.latitudeDelta / 2
        let regionLonMin = mapRegion.center.longitude - mapRegion.span.longitudeDelta / 2
        let regionLonMax = mapRegion.center.longitude + mapRegion.span.longitudeDelta / 2
        
        // Convert to screen coordinates
        // x: longitude maps linearly left to right
        let x = (tileLonMin - regionLonMin) / (regionLonMax - regionLonMin) * size.width
        let width = (tileLonMax - tileLonMin) / (regionLonMax - regionLonMin) * size.width
        
        // y: latitude maps top to bottom (north is higher y in screen coords)
        // In NSImage, y=0 is at bottom, higher latitudes should have higher y values
        let y = (tileLatMin - regionLatMin) / (regionLatMax - regionLatMin) * size.height
        let height = (tileLatMax - tileLatMin) / (regionLatMax - regionLatMin) * size.height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
    
    // Simpler tile positioning using MKMapSnapshotter's coordinate conversion
    func tileToRectUsingSnapshot(tile: (x: Int, y: Int, z: Int), snapshot: MKMapSnapshotter.Snapshot) -> NSRect? {
        let n = pow(2.0, Double(tile.z))
        
        // Get tile corner coordinates
        let west = Double(tile.x) / n * 360.0 - 180.0
        let east = Double(tile.x + 1) / n * 360.0 - 180.0
        let north = atan(sinh(.pi * (1 - 2 * Double(tile.y) / n))) * 180.0 / .pi
        let south = atan(sinh(.pi * (1 - 2 * Double(tile.y + 1) / n))) * 180.0 / .pi
        
        // Convert corners to screen points using MapKit's projection
        let topLeft = snapshot.point(for: CLLocationCoordinate2D(latitude: north, longitude: west))
        let bottomRight = snapshot.point(for: CLLocationCoordinate2D(latitude: south, longitude: east))
        
        // Create rect (note: in NSImage coordinates, y increases upward)
        let rect = NSRect(
            x: topLeft.x,
            y: bottomRight.y,
            width: bottomRight.x - topLeft.x,
            height: topLeft.y - bottomRight.y
        )
        
        return rect
    }
}