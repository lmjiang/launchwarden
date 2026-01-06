import Foundation

/// Parses and modifies launchd plist files
struct PlistParser {
    
    enum PlistError: Error, LocalizedError {
        case fileNotFound(URL)
        case invalidFormat
        case missingLabel
        case writeFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound(let url):
                return "Plist file not found: \(url.path)"
            case .invalidFormat:
                return "Invalid plist format"
            case .missingLabel:
                return "Plist is missing required 'Label' key"
            case .writeFailed(let error):
                return "Failed to write plist: \(error.localizedDescription)"
            }
        }
    }
    
    /// Parse a plist file and return a LaunchService
    /// - Parameters:
    ///   - url: Path to the plist file
    ///   - domain: The service domain
    /// - Returns: A LaunchService populated with plist data
    static func parse(url: URL, domain: ServiceDomain) throws -> LaunchService {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PlistError.fileNotFound(url)
        }
        
        guard let data = FileManager.default.contents(atPath: url.path),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
              ) as? [String: Any] else {
            throw PlistError.invalidFormat
        }
        
        // Use Label from plist, or derive from filename as fallback
        let label: String
        if let plistLabel = plist["Label"] as? String {
            label = plistLabel
        } else {
            // Fallback: use filename without .plist extension
            label = url.deletingPathExtension().lastPathComponent
        }
        
        return LaunchService(
            label: label,
            domain: domain,
            plistPath: url,
            programPath: plist["Program"] as? String,
            programArguments: plist["ProgramArguments"] as? [String],
            runAtLoad: plist["RunAtLoad"] as? Bool ?? false,
            keepAlive: parseKeepAlive(plist["KeepAlive"]),
            startInterval: plist["StartInterval"] as? Int,
            environmentVariables: plist["EnvironmentVariables"] as? [String: String],
            workingDirectory: plist["WorkingDirectory"] as? String,
            standardOutPath: plist["StandardOutPath"] as? String,
            standardErrorPath: plist["StandardErrorPath"] as? String,
            userName: plist["UserName"] as? String,
            groupName: plist["GroupName"] as? String,
            disabled: plist["Disabled"] as? Bool ?? false
        )
    }
    
    /// Parse KeepAlive which can be a bool or a dictionary
    private static func parseKeepAlive(_ value: Any?) -> Bool {
        if let boolValue = value as? Bool {
            return boolValue
        }
        if let dictValue = value as? [String: Any] {
            // If there are any conditions, consider it as keep-alive enabled
            return !dictValue.isEmpty
        }
        return false
    }
    
    /// Read the raw plist content as a dictionary
    /// - Parameter url: Path to the plist file
    /// - Returns: The plist as a dictionary
    static func readRaw(url: URL) throws -> [String: Any] {
        guard let data = FileManager.default.contents(atPath: url.path),
              let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: .mutableContainersAndLeaves,
                format: nil
              ) as? [String: Any] else {
            throw PlistError.invalidFormat
        }
        return plist
    }
    
    /// Write a plist dictionary to a file
    /// - Parameters:
    ///   - plist: The plist dictionary
    ///   - url: Destination URL
    static func write(plist: [String: Any], to url: URL) throws {
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
            try data.write(to: url)
        } catch {
            throw PlistError.writeFailed(error)
        }
    }
    
    /// Get all plist files in a directory
    /// - Parameter directory: The directory path
    /// - Returns: Array of plist file URLs
    static func getPlistFiles(in directory: String) -> [URL] {
        let url = URL(fileURLWithPath: directory)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        return contents.filter { $0.pathExtension == "plist" }
    }
}
