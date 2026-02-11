import AppKit

class WallpaperSetter {
    var onWallpaperSet: (() -> Void)?
    
    func applyWallpaper(path: String) {
        log("Setting wallpaper for all spaces...")
        
        let script = """
        tell application "System Events"
            tell every desktop
                set picture to "\(path)"
            end tell
        end tell
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                log("SUCCESS: Set wallpaper on all spaces")
                DispatchQueue.main.async { [weak self] in
                    self?.onWallpaperSet?()
                }
            } else {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "unknown error"
                log("ERROR: AppleScript failed: \(output)")
            }
        } catch {
            log("ERROR: Failed to run AppleScript: \(error)")
        }
    }
}