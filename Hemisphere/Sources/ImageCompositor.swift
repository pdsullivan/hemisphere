import AppKit
import MapKit
import CoreImage

class ImageCompositor {
    private let tileRenderer = TileRenderer()
    
    func compositeWeatherLayers(on snapshot: MKMapSnapshotter.Snapshot,
                               satelliteTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)],
                               radarTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)],
                               style: MapStyle,
                               completion: @escaping (NSImage?) -> Void) {
        
        let size = snapshot.image.size
        
        // For blackout style, apply filter to base map first
        if style == .blackout {
            applyBlackoutFilter(to: snapshot.image) { [weak self] filteredBase in
                guard let self = self, let baseImage = filteredBase else {
                    completion(snapshot.image)
                    return
                }
                
                // Composite the tiles onto the filtered map
                let finalImage = NSImage(size: size)
                finalImage.lockFocus()
                
                // Enable high-quality image interpolation
                NSGraphicsContext.current?.imageInterpolation = .high
                
                // Draw filtered base map
                baseImage.draw(in: NSRect(origin: .zero, size: size))
                
                // Draw satellite tiles with transparency
                for (tile, tileImage) in satelliteTiles {
                    if let rect = self.tileRenderer.tileToRectUsingSnapshot(tile: tile, snapshot: snapshot) {
                        tileImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.5)
                    }
                }
                
                // Draw radar tiles on top with good visibility
                for (tile, tileImage) in radarTiles {
                    if let rect = self.tileRenderer.tileToRectUsingSnapshot(tile: tile, snapshot: snapshot) {
                        tileImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.8)
                    }
                }
                
                finalImage.unlockFocus()
                completion(finalImage)
            }
        } else {
            // For non-blackout styles, composite normally
            let finalImage = NSImage(size: size)
            finalImage.lockFocus()
            
            // Enable high-quality image interpolation
            NSGraphicsContext.current?.imageInterpolation = .high
            
            // Draw base map
            snapshot.image.draw(in: NSRect(origin: .zero, size: size))
            
            // Draw satellite tiles first (below radar) with transparency
            for (tile, tileImage) in satelliteTiles {
                if let rect = tileRenderer.tileToRectUsingSnapshot(tile: tile, snapshot: snapshot) {
                    tileImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.5)
                }
            }
            
            // Draw radar tiles on top with transparency
            for (tile, tileImage) in radarTiles {
                if let rect = tileRenderer.tileToRectUsingSnapshot(tile: tile, snapshot: snapshot) {
                    tileImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.7)
                }
            }
            
            finalImage.unlockFocus()
            completion(finalImage)
        }
    }
    
    func applyBlackoutFilter(to image: NSImage, completion: @escaping (NSImage?) -> Void) {
        // Create a slightly darker version with increased contrast
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let ciImage = CIImage(bitmapImageRep: bitmap) else {
            completion(image)
            return
        }
        
        let context = CIContext()
        var outputImage = ciImage
        
        // Apply subtle adjustments for blackout effect
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(outputImage, forKey: kCIInputImageKey)
            colorControls.setValue(-0.15, forKey: kCIInputBrightnessKey)  // Less aggressive darkening
            colorControls.setValue(1.3, forKey: kCIInputContrastKey)      // Higher contrast
            colorControls.setValue(0.6, forKey: kCIInputSaturationKey)    // More desaturated
            outputImage = colorControls.outputImage ?? outputImage
        }
        
        // Apply exposure adjustment for deeper blacks
        if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
            exposureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            exposureFilter.setValue(-0.5, forKey: kCIInputEVKey)  // Darken by half a stop
            outputImage = exposureFilter.outputImage ?? outputImage
        }
        
        // Convert back to NSImage
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            let resultImage = NSImage(size: image.size)
            resultImage.lockFocus()
            NSGraphicsContext.current?.imageInterpolation = .high
            let nsImage = NSImage(cgImage: cgImage, size: image.size)
            nsImage.draw(in: NSRect(origin: .zero, size: image.size))
            resultImage.unlockFocus()
            completion(resultImage)
        } else {
            completion(image)
        }
    }
}