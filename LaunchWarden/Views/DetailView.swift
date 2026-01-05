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
    }

    private func itemDetail(_ item: LaunchItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection(item)
                Divider()
                statusSection(item)
                Divider()
                detailsSection(item)
                Divider()
                actionsSection(item)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headerSection(_ item: LaunchItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: item.type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 48, height: 48)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(item.vendor)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func statusSection(_ item: LaunchItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                statusItem(
                    title: "State",
                    value: item.isRunning ? "Running" : (item.isEnabled ? "Loaded" : "Disabled"),
                    color: item.isRunning ? .green : (item.isEnabled ? .blue : .secondary)
                )

                statusItem(
                    title: "Type",
                    value: item.type.rawValue,
                    color: .primary
                )

                if item.runAtLoad {
                    statusItem(
                        title: "Run at Load",
                        value: "Yes",
                        color: .orange
                    )
                }

                if item.keepAlive {
                    statusItem(
                        title: "Keep Alive",
                        value: "Yes",
                        color: .purple
                    )
                }
            }
        }
    }

    private func statusItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }

    private func detailsSection(_ item: LaunchItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Label", value: item.label)
                detailRow(label: "File", value: item.fileName)
                detailRow(label: "Path", value: item.path)

                if let executable = item.executablePath {
                    detailRow(label: "Executable", value: executable)
                }

                if let args = item.programArguments, args.count > 1 {
                    detailRow(label: "Arguments", value: args.dropFirst().joined(separator: " "))
                }
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private func actionsSection(_ item: LaunchItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button {
                    onToggle(item)
                } label: {
                    Label(
                        item.isEnabled ? "Disable" : "Enable",
                        systemImage: item.isEnabled ? "stop.circle" : "play.circle"
                    )
                    .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .tint(item.isEnabled ? .red : .green)

                Button {
                    onRevealInFinder(item)
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                if item.type.requiresAdmin {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield")
                        Text("Requires admin privileges")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("Select a Launch Item")
                .font(.title2)
                .fontWeight(.medium)

            Text("Choose an item from the list to view its details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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
    .frame(width: 500, height: 600)
}

#Preview("Empty") {
    DetailView(
        item: nil,
        onToggle: { _ in },
        onRevealInFinder: { _ in }
    )
    .frame(width: 500, height: 600)
}
