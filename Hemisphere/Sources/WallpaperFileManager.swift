import AppKit

class WallpaperFileManager {
    
    func saveWallpaper(image: NSImage) -> String? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let directory = getWallpaperDirectory()
        let path = "\(directory)/wallpaper-\(timestamp).png"
        
        // Clean up old wallpapers
        cleanupOldWallpapers(in: directory)
        
        // Save as PNG
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            log("ERROR: Failed to create PNG data")
            return nil
        }
        
        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            log("Wallpaper saved to: \(path)")
            return path
        } catch {
            log("ERROR: Failed to save wallpaper: \(error)")
            return nil
        }
    }
    
    private func cleanupOldWallpapers(in directory: String) {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory)
            for file in files where file.hasPrefix("wallpaper-") && file.hasSuffix(".png") {
                let filePath = directory + "/" + file
                try? fileManager.removeItem(atPath: filePath)
            }
        } catch {
            // Ignore cleanup errors
        }
    }
    
    func getWallpaperDirectory() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let hemisphereDir = appSupport.appendingPathComponent("Hemisphere")
        
        if !FileManager.default.fileExists(atPath: hemisphereDir.path) {
            try? FileManager.default.createDirectory(at: hemisphereDir, withIntermediateDirectories: true)
        }
        
        return hemisphereDir.path
    }
}