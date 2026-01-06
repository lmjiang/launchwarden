import Foundation

/// Represents a launchd service (agent or daemon)
struct LaunchService: Identifiable, Hashable, Equatable {
    let id: UUID
    var label: String
    var domain: ServiceDomain
    var plistPath: URL?
    var status: ServiceStatus
    var pid: Int?
    var lastExitStatus: Int?
    
    // Plist properties
    var programPath: String?
    var programArguments: [String]?
    var runAtLoad: Bool
    var keepAlive: Bool
    var startInterval: Int?
    var environmentVariables: [String: String]?
    var workingDirectory: String?
    var standardOutPath: String?
    var standardErrorPath: String?
    var userName: String?
    var groupName: String?
    var disabled: Bool
    
    init(
        id: UUID = UUID(),
        label: String,
        domain: ServiceDomain,
        plistPath: URL? = nil,
        status: ServiceStatus = .unknown,
        pid: Int? = nil,
        lastExitStatus: Int? = nil,
        programPath: String? = nil,
        programArguments: [String]? = nil,
        runAtLoad: Bool = false,
        keepAlive: Bool = false,
        startInterval: Int? = nil,
        environmentVariables: [String: String]? = nil,
        workingDirectory: String? = nil,
        standardOutPath: String? = nil,
        standardErrorPath: String? = nil,
        userName: String? = nil,
        groupName: String? = nil,
        disabled: Bool = false
    ) {
        self.id = id
        self.label = label
        self.domain = domain
        self.plistPath = plistPath
        self.status = status
        self.pid = pid
        self.lastExitStatus = lastExitStatus
        self.programPath = programPath
        self.programArguments = programArguments
        self.runAtLoad = runAtLoad
        self.keepAlive = keepAlive
        self.startInterval = startInterval
        self.environmentVariables = environmentVariables
        self.workingDirectory = workingDirectory
        self.standardOutPath = standardOutPath
        self.standardErrorPath = standardErrorPath
        self.userName = userName
        self.groupName = groupName
        self.disabled = disabled
    }
    
    // MARK: - Hashable
    
    static func == (lhs: LaunchService, rhs: LaunchService) -> Bool {
        lhs.label == rhs.label && lhs.domain == rhs.domain
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(domain)
    }
    
    // MARK: - Computed Properties
    
    /// The executable path (either Program or first ProgramArguments element)
    var executablePath: String? {
        programPath ?? programArguments?.first
    }
    
    /// Display name derived from the label
    var displayName: String {
        // Remove common prefixes for cleaner display
        let prefixes = ["com.apple.", "com.", "org.", "io.", "net."]
        var name = label
        for prefix in prefixes {
            if name.hasPrefix(prefix) {
                name = String(name.dropFirst(prefix.count))
                break
            }
        }
        return name
    }
    
    /// Whether this service can be modified by the current user
    var isEditable: Bool {
        domain.isEditable && !domain.requiresRoot
    }
    
    /// Whether this is a system service (Apple)
    var isSystemService: Bool {
        label.hasPrefix("com.apple.")
    }
}
