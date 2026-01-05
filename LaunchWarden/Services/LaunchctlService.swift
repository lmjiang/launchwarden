import Foundation
import AppKit

actor LaunchctlService {
    static let shared = LaunchctlService()

    private let uid = getuid()

    private init() {}

    func fetchAllItems() async -> [LaunchItem] {
        var items: [LaunchItem] = []

        for type in LaunchItemType.allCases {
            let typeItems = await fetchItems(for: type)
            items.append(contentsOf: typeItems)
        }

        return items.sorted { $0.label < $1.label }
    }

    private func fetchItems(for type: LaunchItemType) async -> [LaunchItem] {
        let directory = type.directory
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: directory) else {
            return []
        }

        guard let files = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return []
        }

        let plistFiles = files.filter { $0.hasSuffix(".plist") }
        var items: [LaunchItem] = []

        let runningServices = await getRunningServices(for: type)
        let disabledServices = await getDisabledServices(for: type)

        for file in plistFiles {
            let path = (directory as NSString).appendingPathComponent(file)

            if let item = parsePlist(at: path, type: type, runningServices: runningServices, disabledServices: disabledServices) {
                items.append(item)
            }
        }

        return items
    }

    private func parsePlist(at path: String, type: LaunchItemType, runningServices: Set<String>, disabledServices: Set<String>) -> LaunchItem? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }

        guard let label = plist["Label"] as? String else {
            return nil
        }

        let program = plist["Program"] as? String
        let programArguments = plist["ProgramArguments"] as? [String]
        let runAtLoad = plist["RunAtLoad"] as? Bool ?? false
        let keepAlive = (plist["KeepAlive"] as? Bool) ?? (plist["KeepAlive"] != nil)

        let isRunning = runningServices.contains(label)
        let isDisabled = disabledServices.contains(label)

        return LaunchItem(
            label: label,
            path: path,
            type: type,
            isEnabled: !isDisabled,
            isRunning: isRunning,
            program: program,
            programArguments: programArguments,
            runAtLoad: runAtLoad,
            keepAlive: keepAlive
        )
    }

    private func getRunningServices(for type: LaunchItemType) async -> Set<String> {
        let domain = type == .systemDaemon ? "system" : "gui/\(uid)"
        let output = await runCommand("/bin/launchctl", arguments: ["print", domain])

        var services = Set<String>()
        let lines = output.components(separatedBy: "\n")

        var inServicesSection = false
        for line in lines {
            if line.contains("services = {") {
                inServicesSection = true
                continue
            }
            if inServicesSection {
                if line.contains("}") {
                    break
                }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if let labelEnd = trimmed.firstIndex(of: " ") {
                    let label = String(trimmed[..<labelEnd])
                    if !label.isEmpty && !label.hasPrefix("0x") {
                        services.insert(label)
                    }
                }
            }
        }

        return services
    }

    private func getDisabledServices(for type: LaunchItemType) async -> Set<String> {
        let domain = type == .systemDaemon ? "system" : "gui/\(uid)"
        let output = await runCommand("/bin/launchctl", arguments: ["print-disabled", domain])

        var disabled = Set<String>()
        let lines = output.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("=> disabled") || trimmed.contains("=> true") {
                if let quoteStart = trimmed.firstIndex(of: "\""),
                   let quoteEnd = trimmed[trimmed.index(after: quoteStart)...].firstIndex(of: "\"") {
                    let label = String(trimmed[trimmed.index(after: quoteStart)..<quoteEnd])
                    disabled.insert(label)
                }
            }
        }

        return disabled
    }

    func enable(item: LaunchItem) async -> Result<Void, LaunchctlError> {
        let domain = item.type == .systemDaemon ? "system" : "gui/\(uid)"

        if item.type.requiresAdmin {
            return await runPrivilegedCommands(for: item, domain: domain, enable: true)
        }

        _ = await runCommand("/bin/launchctl", arguments: ["enable", "\(domain)/\(item.label)"])
        let result = await runCommand("/bin/launchctl", arguments: ["bootstrap", domain, item.path])

        if result.lowercased().contains("error") && !result.contains("already bootstrapped") {
            return .failure(.commandFailed(result))
        }

        return .success(())
    }

    func disable(item: LaunchItem) async -> Result<Void, LaunchctlError> {
        let domain = item.type == .systemDaemon ? "system" : "gui/\(uid)"

        if item.type.requiresAdmin {
            return await runPrivilegedCommands(for: item, domain: domain, enable: false)
        }

        _ = await runCommand("/bin/launchctl", arguments: ["bootout", "\(domain)/\(item.label)"])
        let result = await runCommand("/bin/launchctl", arguments: ["disable", "\(domain)/\(item.label)"])

        if result.lowercased().contains("error") {
            return .failure(.commandFailed(result))
        }

        return .success(())
    }

    private func runPrivilegedCommands(for launchItem: LaunchItem, domain: String, enable: Bool) async -> Result<Void, LaunchctlError> {
        let command: String
        if enable {
            if launchItem.type == .systemDaemon {
                command = "/bin/launchctl enable \(domain)/\(launchItem.label); /bin/launchctl bootstrap \(domain) '\(launchItem.path)'"
            } else {
                command = "/bin/launchctl asuser \(uid) /bin/launchctl enable \(domain)/\(launchItem.label); /bin/launchctl asuser \(uid) /bin/launchctl bootstrap \(domain) '\(launchItem.path)'"
            }
        } else {
            if launchItem.type == .systemDaemon {
                command = "/bin/launchctl bootout \(domain)/\(launchItem.label) 2>/dev/null; /bin/launchctl disable \(domain)/\(launchItem.label)"
            } else {
                command = "/bin/launchctl asuser \(uid) /bin/launchctl bootout \(domain)/\(launchItem.label) 2>/dev/null; /bin/launchctl asuser \(uid) /bin/launchctl disable \(domain)/\(launchItem.label)"
            }
        }

        let script = "do shell script \"\(command)\" with administrator privileges"
        return await runAppleScript(script)
    }

    private func runAppleScript(_ script: String) async -> Result<Void, LaunchctlError> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                _ = appleScript?.executeAndReturnError(&error)

                if let error = error {
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"

                    if errorNumber == -128 {
                        continuation.resume(returning: .failure(.userCancelled))
                    } else {
                        continuation.resume(returning: .failure(.commandFailed(message)))
                    }
                } else {
                    continuation.resume(returning: .success(()))
                }
            }
        }
    }

    private nonisolated func runCommand(_ command: String, arguments: [String]) async -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }

    func revealInFinder(item: LaunchItem) {
        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
    }
}

enum LaunchctlError: LocalizedError {
    case commandFailed(String)
    case userCancelled
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return "Command failed: \(message)"
        case .userCancelled:
            return "Operation cancelled by user"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
