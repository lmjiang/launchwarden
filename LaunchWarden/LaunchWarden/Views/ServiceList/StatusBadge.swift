import SwiftUI

struct StatusBadge: View {
    let status: ServiceStatus
    var compact: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            if !compact {
                Text(status.shortText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, compact ? 0 : 8)
        .padding(.vertical, compact ? 0 : 4)
        .background(compact ? Color.clear : status.color.opacity(0.1))
        .cornerRadius(4)
    }
}

#Preview {
    VStack(spacing: 10) {
        StatusBadge(status: .running(pid: 123))
        StatusBadge(status: .stopped)
        StatusBadge(status: .failed(exitCode: 1))
        StatusBadge(status: .disabled)
        StatusBadge(status: .unloaded)
        StatusBadge(status: .running(pid: 123), compact: true)
    }
    .padding()
}
