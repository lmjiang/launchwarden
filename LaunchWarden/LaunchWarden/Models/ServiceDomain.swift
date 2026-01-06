import Foundation

/// Represents the different domains where launchd services can be located
enum ServiceDomain: String, CaseIterable, Identifiable, Hashable {
    case userAgents = "User Agents"
    case globalAgents = "Global Agents"
    case globalDaemons = "Global Daemons"
    case systemAgents = "System Agents"
    case systemDaemons = "System Daemons"
    
    var id: String { rawValue }
    
    /// The file system path for this domain's plist files
    var path: String {
        switch self {
        case .userAgents:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/LaunchAgents").path
        case .globalAgents:
            return "/Library/LaunchAgents"
        case .globalDaemons:
            return "/Library/LaunchDaemons"
        case .systemAgents:
            return "/System/Library/LaunchAgents"
        case .systemDaemons:
            return "/System/Library/LaunchDaemons"
        }
    }
    
    /// The launchctl domain target for operations
    var domainTarget: String {
        switch self {
        case .userAgents:
            return "gui/\(getuid())"
        case .globalAgents:
            return "gui/\(getuid())"
        case .globalDaemons:
            return "system"
        case .systemAgents:
            return "gui/\(getuid())"
        case .systemDaemons:
            return "system"
        }
    }
    
    /// Whether modifying services in this domain requires root access
    var requiresRoot: Bool {
        switch self {
        case .userAgents:
            return false
        case .globalAgents, .globalDaemons:
            return true
        case .systemAgents, .systemDaemons:
            return true
        }
    }
    
    /// Whether services in this domain can be edited
    var isEditable: Bool {
        switch self {
        case .userAgents:
            return true
        case .globalAgents, .globalDaemons:
            return true  // Editable with admin rights
        case .systemAgents, .systemDaemons:
            return false  // System Integrity Protection
        }
    }
    
    /// SF Symbol icon for this domain
    var icon: String {
        switch self {
        case .userAgents:
            return "person.circle"
        case .globalAgents:
            return "globe"
        case .globalDaemons:
            return "server.rack"
        case .systemAgents:
            return "apple.logo"
        case .systemDaemons:
            return "gear.badge.checkmark"
        }
    }
    
    /// Description for the domain
    var description: String {
        switch self {
        case .userAgents:
            return "Per-user background services"
        case .globalAgents:
            return "System-wide user services"
        case .globalDaemons:
            return "System-wide background daemons"
        case .systemAgents:
            return "Apple system agents (read-only)"
        case .systemDaemons:
            return "Apple system daemons (read-only)"
        }
    }
    
    /// Whether this domain is for system (Apple) services
    var isSystem: Bool {
        switch self {
        case .systemAgents, .systemDaemons:
            return true
        default:
            return false
        }
    }
}
