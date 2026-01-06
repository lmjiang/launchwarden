import Foundation
import Combine

/// Watches for file system changes in specified directories
class FileWatcher: ObservableObject {
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [Int32] = []
    
    @Published var lastChange: Date = Date()
    
    /// Start watching the specified paths for changes
    /// - Parameter paths: Array of directory paths to watch
    func watch(paths: [String]) {
        stop()
        
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else { continue }
            
            let fd = open(path, O_EVTONLY)
            guard fd >= 0 else { continue }
            
            fileDescriptors.append(fd)
            
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename, .extend],
                queue: .main
            )
            
            source.setEventHandler { [weak self] in
                // Defer the @Published update to avoid publishing during view updates
                DispatchQueue.main.async {
                    self?.lastChange = Date()
                }
            }
            
            source.setCancelHandler {
                close(fd)
            }
            
            source.resume()
            sources.append(source)
        }
    }
    
    /// Stop watching all paths
    func stop() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
        fileDescriptors.removeAll()
    }
    
    deinit {
        stop()
    }
}
