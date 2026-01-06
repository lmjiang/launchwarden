import SwiftUI

struct ServiceRowView: View {
    let service: LaunchService
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            StatusBadge(status: service.status, compact: true)
            
            // Service info
            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .font(.system(.body, design: .default))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                
                Text(service.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Quick status info
            if service.status.isActive, let pid = service.pid {
                Text("PID: \(pid)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Domain badge for mixed views
            if service.domain.requiresRoot {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .help("Requires administrator privileges")
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack {
        ServiceRowView(
            service: LaunchService(
                label: "com.example.mydaemon",
                domain: .userAgents,
                status: .running(pid: 1234),
                pid: 1234
            ),
            isSelected: false
        )
        
        ServiceRowView(
            service: LaunchService(
                label: "com.apple.finder.sync",
                domain: .globalDaemons,
                status: .stopped
            ),
            isSelected: true
        )
        
        ServiceRowView(
            service: LaunchService(
                label: "org.mongodb.mongod",
                domain: .userAgents,
                status: .failed(exitCode: 1)
            ),
            isSelected: false
        )
    }
    .padding()
}
