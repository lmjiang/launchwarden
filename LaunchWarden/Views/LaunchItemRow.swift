import SwiftUI

struct LaunchItemRow: View {
    let item: LaunchItem
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(item.type.rawValue, systemImage: item.type.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if item.isRunning {
                        statusBadge(text: "Running", color: .green)
                    } else if item.isEnabled {
                        statusBadge(text: "Loaded", color: .blue)
                    } else {
                        statusBadge(text: "Disabled", color: .secondary)
                    }
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .contentShape(Rectangle())
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay {
                if item.isRunning {
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 14, height: 14)
                }
            }
    }

    private var statusColor: Color {
        if item.isRunning {
            return .green
        } else if item.isEnabled {
            return .blue
        } else {
            return .gray
        }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 0) {
        LaunchItemRow(
            item: LaunchItem(
                label: "com.apple.Safari.helper",
                path: "/Library/LaunchAgents/com.apple.Safari.helper.plist",
                type: .userAgent,
                isEnabled: true,
                isRunning: true
            ),
            isSelected: false,
            onToggle: {}
        )

        Divider()

        LaunchItemRow(
            item: LaunchItem(
                label: "com.docker.helper",
                path: "/Library/LaunchDaemons/com.docker.helper.plist",
                type: .systemDaemon,
                isEnabled: true,
                isRunning: false
            ),
            isSelected: true,
            onToggle: {}
        )

        Divider()

        LaunchItemRow(
            item: LaunchItem(
                label: "com.old.service",
                path: "/Library/LaunchAgents/com.old.service.plist",
                type: .systemAgent,
                isEnabled: false,
                isRunning: false
            ),
            isSelected: false,
            onToggle: {}
        )
    }
    .frame(width: 400)
}
