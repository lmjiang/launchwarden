import SwiftUI

struct DetailView: View {
    let item: LaunchItem?
    let onToggle: (LaunchItem) -> Void
    let onRevealInFinder: (LaunchItem) -> Void

    var body: some View {
        Group {
            if let item = item {
                itemDetail(item)
            } else {
                emptyState
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func itemDetail(_ item: LaunchItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Card
                headerCard(item)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Status Section
                sectionCard(title: "Status") {
                    statusContent(item)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Details Section
                sectionCard(title: "Configuration") {
                    detailsContent(item)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Actions Section
                actionsCard(item)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
        }
    }

    private func headerCard(_ item: LaunchItem) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [statusColor(for: item).opacity(0.8), statusColor(for: item)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: item.type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)

                Text(item.vendor)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
        }
    }

    private func statusContent(_ item: LaunchItem) -> some View {
        HStack(spacing: 20) {
            statusPill(
                icon: item.isRunning ? "play.circle.fill" : (item.isEnabled ? "circle.fill" : "stop.circle.fill"),
                title: "State",
                value: item.isRunning ? "Running" : (item.isEnabled ? "Loaded" : "Disabled"),
                color: statusColor(for: item)
            )

            Divider()
                .frame(height: 36)

            statusPill(
                icon: item.type.icon,
                title: "Type",
                value: item.type.rawValue,
                color: .secondary
            )

            if item.runAtLoad {
                Divider()
                    .frame(height: 36)

                statusPill(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Auto Start",
                    value: "Yes",
                    color: .orange
                )
            }

            if item.keepAlive {
                Divider()
                    .frame(height: 36)

                statusPill(
                    icon: "heart.circle.fill",
                    title: "Keep Alive",
                    value: "Yes",
                    color: .pink
                )
            }

            Spacer()
        }
    }

    private func statusPill(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 13, weight: .medium))
            }
        }
    }

    private func detailsContent(_ item: LaunchItem) -> some View {
        VStack(spacing: 12) {
            detailRow(label: "Label", value: item.label, monospace: true)

            Divider()

            detailRow(label: "File", value: item.fileName, monospace: false)

            Divider()

            detailRow(label: "Path", value: item.path, monospace: true)

            if let executable = item.executablePath {
                Divider()
                detailRow(label: "Executable", value: executable, monospace: true)
            }

            if let args = item.programArguments, args.count > 1 {
                Divider()
                detailRow(label: "Arguments", value: args.dropFirst().joined(separator: " "), monospace: true)
            }
        }
    }

    private func detailRow(label: String, value: String, monospace: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            if monospace {
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(3)
            } else {
                Text(value)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionsCard(_ item: LaunchItem) -> some View {
        HStack(spacing: 12) {
            Button {
                onToggle(item)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: item.isEnabled ? "stop.circle" : "play.circle")
                    Text(item.isEnabled ? "Disable" : "Enable")
                }
                .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(item.isEnabled ? .red : .green)
            .controlSize(.large)

            Button {
                onRevealInFinder(item)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                    Text("Reveal in Finder")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            Button {
                openLogsInConsole(item)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                    Text("View in Console")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()

            if item.type.requiresAdmin {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 10))
                    Text("Admin Required")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                }
            }
        }
    }

    private func statusColor(for item: LaunchItem) -> Color {
        if item.isRunning {
            return .green
        } else if item.isEnabled {
            return .blue
        } else {
            return .gray
        }
    }
    
    private func openLogsInConsole(_ item: LaunchItem) {
        // Open Console.app with a predicate filter for this service
        // Using `log show` command to get logs, then open Console
        let predicate = "subsystem contains '\\(item.label)' OR process contains '\\(item.label)'"
        let script = """
        tell application "Console"
            activate
        end tell
        """
        
        // First, try to open Console.app
        if let consoleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Console") {
            NSWorkspace.shared.open(consoleURL)
        }
        
        // Copy a helpful log command to clipboard so user can paste it
        let logCommand = "log show --predicate '\\(predicate)' --last 1h --style compact"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(logCommand, forType: .string)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "sidebar.right")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 6) {
                Text("No Selection")
                    .font(.system(size: 16, weight: .semibold))

                Text("Select an item to view details")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("With Item") {
    DetailView(
        item: LaunchItem(
            label: "com.apple.Safari.SafeBrowsing.helper",
            path: "/Library/LaunchAgents/com.apple.Safari.SafeBrowsing.helper.plist",
            type: .userAgent,
            isEnabled: true,
            isRunning: true,
            program: "/Applications/Safari.app/Contents/MacOS/SafeBrowsingHelper",
            programArguments: ["/Applications/Safari.app/Contents/MacOS/SafeBrowsingHelper", "--arg1", "--arg2"],
            runAtLoad: true,
            keepAlive: true
        ),
        onToggle: { _ in },
        onRevealInFinder: { _ in }
    )
    .frame(width: 480, height: 600)
}

#Preview("Empty") {
    DetailView(
        item: nil,
        onToggle: { _ in },
        onRevealInFinder: { _ in }
    )
    .frame(width: 480, height: 600)
}
