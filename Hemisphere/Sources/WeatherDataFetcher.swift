import Foundation
import AppKit

class WeatherDataFetcher {
    
    func fetchWeatherLayers(completion: @escaping (WeatherLayers) -> Void) {
        let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json")!
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                log("ERROR: Failed to fetch weather data: \(error?.localizedDescription ?? "unknown")")
                completion(WeatherLayers())
                return
            }
            
            do {
                let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)
                var layers = WeatherLayers()
                
                // Get latest radar frame
                if let latestRadar = response.radar.past.last {
                    layers.radarPath = latestRadar.path
                    log("Radar frames available: \(response.radar.past.count)")
                }
                
                // Get latest satellite frame
                if let satellite = response.satellite {
                    log("Satellite data present in response")
                    if let infrared = satellite.infrared {
                        log("Infrared frames available: \(infrared.count)")
                        if let latestSatellite = infrared.last {
                            layers.satellitePath = latestSatellite.path
                            log("Using satellite path: \(latestSatellite.path)")
                        }
                    } else {
                        log("No infrared data in satellite response")
                    }
                } else {
                    log("No satellite data in API response")
                }
                
                completion(layers)
            } catch {
                log("ERROR: Failed to decode weather response: \(error)")
                // Log raw response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                    log("Raw API response (first 500 chars): \(String(rawString.prefix(500)))")
                }
                completion(WeatherLayers())
            }
        }.resume()
    }
    
    func fetchWeatherTiles(tiles: [(x: Int, y: Int, z: Int)], 
                          layers: WeatherLayers,
                          completion: @escaping (_ satelliteTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)],
                                                _ radarTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)]) -> Void) {
        let group = DispatchGroup()
        var satelliteTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)] = []
        var radarTiles: [(tile: (x: Int, y: Int, z: Int), image: NSImage)] = []
        let lock = NSLock()
        
        // Fetch satellite tiles if enabled
        if let satellitePath = layers.satellitePath {
            log("Fetching satellite tiles with path: \(satellitePath)")
            for tile in tiles {
                group.enter()
                // Satellite infrared tile URL
                let urlString = "https://tilecache.rainviewer.com\(satellitePath)/512/\(tile.z)/\(tile.x)/\(tile.y)/0/0_0.png"
                
                guard let url = URL(string: urlString) else {
                    log("Invalid satellite URL: \(urlString)")
                    group.leave()
                    continue
                }
                
                URLSession.shared.dataTask(with: url) { data, response, error in
                    defer { group.leave() }
                    if let error = error {
                        log("Satellite tile error: \(error.localizedDescription)")
                        return
                    }
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        log("Satellite tile HTTP \(httpResponse.statusCode) for \(tile)")
                        return
                    }
                    if let data = data, let image = NSImage(data: data) {
                        lock.lock()
                        satelliteTiles.append((tile, image))
                        lock.unlock()
                    }
                }.resume()
            }
        } else {
            log("No satellite path available")
        }
        
        // Fetch radar tiles if enabled
        if let radarPath = layers.radarPath {
            for tile in tiles {
                group.enter()
                // Radar tile URL with color scheme 2 (TITAN)
                // Try to use higher resolution by using larger tile size
                let tileSize = 512  // RainViewer supports 256 and 512
                let urlString = "https://tilecache.rainviewer.com\(radarPath)/\(tileSize)/\(tile.z)/\(tile.x)/\(tile.y)/2/1_1.png"
                guard let url = URL(string: urlString) else {
                    group.leave()
                    continue
                }
                
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    defer { group.leave() }
                    if let data = data, let image = NSImage(data: data) {
                        lock.lock()
                        radarTiles.append((tile, image))
                        lock.unlock()
                    }
                }.resume()
            }
        }
        
        group.notify(queue: .main) {
            log("Downloaded \(satelliteTiles.count) satellite tiles, \(radarTiles.count) radar tiles")
            completion(satelliteTiles, radarTiles)
        }
    }
}