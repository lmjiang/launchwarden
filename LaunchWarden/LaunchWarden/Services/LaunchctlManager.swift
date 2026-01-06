import Foundation

/// Manages launchctl operations
actor LaunchctlManager {
    private let uid = getuid()
    
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
    
    /// List all loaded services for the current user
    /// - Returns: Dictionary mapping service labels to their PIDs and status
    func listServices() async -> [String: (pid: Int?, status: Int?)] {
        let output = await runCommand("/bin/launchctl", arguments: ["list"])
        return parseListOutput(output)
    }
    
    /// Parse the output of `launchctl list`
    private func parseListOutput(_ output: String) -> [String: (pid: Int?, status: Int?)] {
        var services: [String: (pid: Int?, status: Int?)] = [:]
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines.dropFirst() { // Skip header line
            let components = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard components.count >= 3 else { continue }
            
            let pidStr = String(components[0]).trimmingCharacters(in: .whitespaces)
            let statusStr = String(components[1]).trimmingCharacters(in: .whitespaces)
            let label = String(components[2]).trimmingCharacters(in: .whitespaces)
            
            guard !label.isEmpty else { continue }
            
            let pid = pidStr == "-" ? nil : Int(pidStr)
            let status = statusStr == "-" ? nil : Int(statusStr)
            
            services[label] = (pid, status)
        }
        
        return services
    }
    
    /// Get the domain target string for a service domain
    private func getDomainTarget(_ domain: ServiceDomain) -> String {
        switch domain {
        case .userAgents:
            return "gui/\(uid)"
        case .globalAgents:
            return "gui/\(uid)"
        case .globalDaemons, .systemDaemons:
            return "system"
        case .systemAgents:
            return "gui/\(uid)"
        }
    }
    
    /// Enable and start a service
    func enable(label: String, plistPath: URL, domain: ServiceDomain) async throws {
        let domainTarget = getDomainTarget(domain)
        
        if domain.requiresRoot {
            try await runPrivilegedCommands(
                label: label,
                plistPath: plistPath.path,
                domain: domainTarget,
                isSystemDaemon: domain == .systemDaemons,
                enable: true
            )
        } else {
            // Enable the service
            _ = await runCommand("/bin/launchctl", arguments: ["enable", "\(domainTarget)/\(label)"])
            // Bootstrap (load) the service
            let result = await runCommand("/bin/launchctl", arguments: ["bootstrap", domainTarget, plistPath.path])
            
            if result.lowercased().contains("error") && !result.contains("already bootstrapped") {
                throw LaunchctlError.commandFailed(result)
            }
        }
    }
    
    /// Disable and stop a service
    func disable(label: String, domain: ServiceDomain) async throws {
        let domainTarget = getDomainTarget(domain)
        
        if domain.requiresRoot {
            // For admin operations, we need to find the plist path
            // Use an empty path for now, the command will work with just the label
            try await runPrivilegedCommands(
                label: label,
                plistPath: "",
                domain: domainTarget,
                isSystemDaemon: domain == .systemDaemons,
                enable: false
            )
        } else {
            // Bootout (unload) the service - ignore errors if not loaded
            _ = await runCommand("/bin/launchctl", arguments: ["bootout", "\(domainTarget)/\(label)"])
            // Disable the service
            let result = await runCommand("/bin/launchctl", arguments: ["disable", "\(domainTarget)/\(label)"])
            
            if result.lowercased().contains("error") && !result.contains("not found") {
                throw LaunchctlError.commandFailed(result)
            }
        }
    }
    
    /// Load a service from a plist file (legacy method)
    func load(plistPath: URL, domain: ServiceDomain) async throws {
        try await enable(label: "", plistPath: plistPath, domain: domain)
    }
    
    /// Unload a service (legacy method)
    func unload(plistPath: URL, domain: ServiceDomain) async throws {
        // Extract label from plist
        if let data = FileManager.default.contents(atPath: plistPath.path),
           let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
           let label = plist["Label"] as? String {
            try await disable(label: label, domain: domain)
        }
    }
    
    /// Start a service (enable + bootstrap)
    func start(label: String, plistPath: URL, domain: ServiceDomain) async throws {
        try await enable(label: label, plistPath: plistPath, domain: domain)
    }
    
    /// Stop a service (bootout + disable)
    func stop(label: String, domain: ServiceDomain) async throws {
        try await disable(label: label, domain: domain)
    }
    
    /// Run privileged launchctl commands using AppleScript
    private func runPrivilegedCommands(
        label: String,
        plistPath: String,
        domain: String,
        isSystemDaemon: Bool,
        enable: Bool
    ) async throws {
        let command: String
        
        if enable {
            if isSystemDaemon {
                command = "/bin/launchctl enable \(domain)/\(label); /bin/launchctl bootstrap \(domain) '\(plistPath)'"
            } else {
                command = "/bin/launchctl asuser \(uid) /bin/launchctl enable \(domain)/\(label); /bin/launchctl asuser \(uid) /bin/launchctl bootstrap \(domain) '\(plistPath)'"
            }
        } else {
            if isSystemDaemon {
                command = "/bin/launchctl bootout \(domain)/\(label) 2>/dev/null; /bin/launchctl disable \(domain)/\(label)"
            } else {
                command = "/bin/launchctl asuser \(uid) /bin/launchctl bootout \(domain)/\(label) 2>/dev/null; /bin/launchctl asuser \(uid) /bin/launchctl disable \(domain)/\(label)"
            }
        }
        
        let script = "do shell script \"\(command)\" with administrator privileges"
        try await runAppleScript(script)
    }
    
    /// Execute AppleScript for privileged operations
    private func runAppleScript(_ script: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                _ = appleScript?.executeAndReturnError(&error)
                
                if let error = error {
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    
                    if errorNumber == -128 {
                        continuation.resume(throwing: LaunchctlError.userCancelled)
                    } else {
                        continuation.resume(throwing: LaunchctlError.commandFailed(message))
                    }
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Run a shell command and return the output
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
    
    /// Get the reason for last exit using `launchctl blame`
    func blame(label: String, domain: ServiceDomain) async -> String {
        let target = "\(getDomainTarget(domain))/\(label)"
        return await runCommand("/bin/launchctl", arguments: ["blame", target])
    }
}
