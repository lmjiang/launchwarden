import SwiftUI

struct LaunchItemRow: View {
    let item: LaunchItem
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator with glow effect
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                if item.isRunning {
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.vendor)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)

                    Text("•")
                        .font(.system(size: 9))
                        .foregroundStyle(.quaternary)

                    HStack(spacing: 4) {
                        Image(systemName: item.type.icon)
                            .font(.system(size: 9))
                        Text(item.type.rawValue)
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Status badge
            statusBadge

            // Toggle
            Toggle("", isOn: Binding(
                get: { item.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)
            .scaleEffect(0.8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        } else if isHovered {
            return Color.primary.opacity(0.04)
        }
        return Color.clear
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else if isHovered {
            return Color.primary.opacity(0.08)
        }
        return Color.primary.opacity(0.06)
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

    @ViewBuilder
    private var statusBadge: some View {
        let (text, color) = statusInfo
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(color.opacity(0.12))
            }
    }

    private var statusInfo: (String, Color) {
        if item.isRunning {
            return ("Running", .green)
        } else if item.isEnabled {
            return ("Loaded", .blue)
        } else {
            return ("Disabled", .secondary)
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        LaunchItemRow(
            item: LaunchItem(
                label: "com.apple.Safari.SafeBrowsing",
                path: "/Library/LaunchAgents/com.apple.Safari.SafeBrowsing.plist",
                type: .userAgent,
                isEnabled: true,
                isRunning: true
            ),
            isSelected: false,
            onToggle: {}
        )

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
    .padding()
    .frame(width: 450)
}
