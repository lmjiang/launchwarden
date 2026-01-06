import Foundation
import SwiftUI

/// Represents the current status of a launchd service
enum ServiceStatus: Equatable, Hashable {
    case running(pid: Int)
    case stopped
    case loaded
    case unloaded
    case failed(exitCode: Int)
    case disabled
    case unknown
    
    /// Whether the service is currently active
    var isActive: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }
    
    /// Whether the service has encountered an error
    var hasError: Bool {
        switch self {
        case .failed:
            return true
        default:
            return false
        }
    }
    
    /// Display text for the status
    var displayText: String {
        switch self {
        case .running(let pid):
            return "Running (PID: \(pid))"
        case .stopped:
            return "Stopped"
        case .loaded:
            return "Loaded"
        case .unloaded:
            return "Not Loaded"
        case .failed(let exitCode):
            return "Failed (Exit: \(exitCode))"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
    
    /// Short status text
    var shortText: String {
        switch self {
        case .running:
            return "Running"
        case .stopped:
            return "Stopped"
        case .loaded:
            return "Loaded"
        case .unloaded:
            return "Not Loaded"
        case .failed:
            return "Failed"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
    
    /// Color for status indicator
    var color: Color {
        switch self {
        case .running:
            return .green
        case .stopped, .loaded:
            return .orange
        case .unloaded:
            return .secondary
        case .failed:
            return .red
        case .disabled:
            return .gray
        case .unknown:
            return .secondary
        }
    }
    
    /// SF Symbol for status
    var icon: String {
        switch self {
        case .running:
            return "circle.fill"
        case .stopped, .loaded:
            return "circle.fill"
        case .unloaded:
            return "circle"
        case .failed:
            return "exclamationmark.circle.fill"
        case .disabled:
            return "minus.circle.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }
}
