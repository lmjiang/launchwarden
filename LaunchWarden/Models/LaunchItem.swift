import Foundation

enum LaunchItemType: String, CaseIterable, Identifiable {
    case userAgent = "User Agent"
    case systemAgent = "System Agent"
    case systemDaemon = "System Daemon"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .userAgent: return "person.circle"
        case .systemAgent: return "gearshape.circle"
        case .systemDaemon: return "server.rack"
        }
    }

    var directory: String {
        switch self {
        case .userAgent:
            return NSHomeDirectory() + "/Library/LaunchAgents"
        case .systemAgent:
            return "/Library/LaunchAgents"
        case .systemDaemon:
            return "/Library/LaunchDaemons"
        }
    }

    var requiresAdmin: Bool {
        switch self {
        case .userAgent: return false
        case .systemAgent, .systemDaemon: return true
        }
    }
}

struct LaunchItem: Identifiable, Hashable {
    let id: UUID
    let label: String
    let path: String
    let type: LaunchItemType
    var isEnabled: Bool
    var isRunning: Bool
    let program: String?
    let programArguments: [String]?
    let runAtLoad: Bool
    let keepAlive: Bool

    init(
        id: UUID = UUID(),
        label: String,
        path: String,
        type: LaunchItemType,
        isEnabled: Bool = true,
        isRunning: Bool = false,
        program: String? = nil,
        programArguments: [String]? = nil,
        runAtLoad: Bool = false,
        keepAlive: Bool = false
    ) {
        self.id = id
        self.label = label
        self.path = path
        self.type = type
        self.isEnabled = isEnabled
        self.isRunning = isRunning
        self.program = program
        self.programArguments = programArguments
        self.runAtLoad = runAtLoad
        self.keepAlive = keepAlive
    }

    var displayName: String {
        let components = label.components(separatedBy: ".")
        if components.count >= 3 {
            return components.suffix(from: 2).joined(separator: ".")
        }
        return label
    }

    var vendor: String {
        let components = label.components(separatedBy: ".")
        if components.count >= 2 {
            return components.prefix(2).joined(separator: ".")
        }
        return label
    }

    var fileName: String {
        (path as NSString).lastPathComponent
    }

    var executablePath: String? {
        if let program = program {
            return program
        }
        return programArguments?.first
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: LaunchItem, rhs: LaunchItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum SidebarFilter: Hashable, CaseIterable {
    case all
    case userAgent
    case systemAgent
    case systemDaemon

    var title: String {
        switch self {
        case .all: return "All"
        case .userAgent: return "User Agents"
        case .systemAgent: return "System Agents"
        case .systemDaemon: return "System Daemons"
        }
    }

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .userAgent: return "person.circle"
        case .systemAgent: return "gearshape.circle"
        case .systemDaemon: return "server.rack"
        }
    }

    var itemType: LaunchItemType? {
        switch self {
        case .all: return nil
        case .userAgent: return .userAgent
        case .systemAgent: return .systemAgent
        case .systemDaemon: return .systemDaemon
        }
    }
}
