import SwiftUI

struct ServiceDetailView: View {
    let service: LaunchService
    @EnvironmentObject var serviceMonitor: ServiceMonitor
    @State private var selectedTab: DetailTab = .info
    @State private var isOperationInProgress = false
    
    enum DetailTab: String, CaseIterable {
        case info = "Info"
        case plist = "Plist"
        case logs = "Logs"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Card
                headerCard
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Status Section
                sectionCard(title: "Status") {
                    statusContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Configuration Section
                sectionCard(title: "Configuration") {
                    configurationContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Actions Section
                actionsCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .id(service.id) // Key for smooth transitions
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
    
    // MARK: - Header Card
    
    private var headerCard: some View {
        HStack(spacing: 16) {
            // Icon with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [statusColor.opacity(0.8), statusColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: service.domain.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(service.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                
                Text(service.label)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            // Status badge
            statusBadge
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
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(service.status.shortText)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(statusColor.opacity(0.12))
        }
    }
    
    // MARK: - Section Card
    
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
    
    // MARK: - Status Content
    
    private var statusContent: some View {
        HStack(spacing: 20) {
            statusPill(
                icon: service.status.isActive ? "play.circle.fill" : "stop.circle.fill",
                title: "State",
                value: service.status.shortText,
                color: statusColor
            )
            
            Divider().frame(height: 36)
            
            statusPill(
                icon: service.domain.icon,
                title: "Type",
                value: service.domain.rawValue,
                color: .secondary
            )
            
            if service.runAtLoad {
                Divider().frame(height: 36)
                statusPill(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Auto Start",
                    value: "Yes",
                    color: .orange
                )
            }
            
            if service.keepAlive {
                Divider().frame(height: 36)
                statusPill(
                    icon: "heart.circle.fill",
                    title: "Keep Alive",
                    value: "Yes",
                    color: .pink
                )
            }
            
            if let pid = service.pid {
                Divider().frame(height: 36)
                statusPill(
                    icon: "number.circle.fill",
                    title: "PID",
                    value: "\(pid)",
                    color: .blue
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
    
    // MARK: - Configuration Content
    
    private var configurationContent: some View {
        VStack(spacing: 12) {
            detailRow(label: "Label", value: service.label, monospace: true)
            
            if let execPath = service.executablePath {
                Divider()
                detailRow(label: "Executable", value: execPath, monospace: true)
            }
            
            if let args = service.programArguments, args.count > 1 {
                Divider()
                detailRow(label: "Arguments", value: args.dropFirst().joined(separator: " "), monospace: true)
            }
            
            if let workDir = service.workingDirectory {
                Divider()
                detailRow(label: "Working Dir", value: workDir, monospace: true)
            }
            
            if let stdout = service.standardOutPath {
                Divider()
                detailRow(label: "Stdout", value: stdout, monospace: true)
            }
            
            if let stderr = service.standardErrorPath {
                Divider()
                detailRow(label: "Stderr", value: stderr, monospace: true)
            }
            
            if let plistPath = service.plistPath {
                Divider()
                HStack {
                    detailRow(label: "Plist", value: plistPath.lastPathComponent, monospace: false)
                    
                    Button {
                        NSWorkspace.shared.selectFile(plistPath.path, inFileViewerRootedAtPath: "")
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Reveal in Finder")
                }
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
    
    // MARK: - Actions Card
    
    private var actionsCard: some View {
        HStack(spacing: 12) {
            Button {
                performOperation {
                    if service.status.isActive {
                        await serviceMonitor.stopService(service)
                    } else {
                        await serviceMonitor.startService(service)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if isOperationInProgress {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: service.status.isActive ? "stop.circle" : "play.circle")
                    }
                    Text(service.status.isActive ? "Disable" : "Enable")
                }
                .frame(minWidth: 90)
            }
            .buttonStyle(.borderedProminent)
            .tint(service.status.isActive ? .red : .green)
            .controlSize(.large)
            .disabled(isOperationInProgress)
            
            if let plistPath = service.plistPath {
                Button {
                    NSWorkspace.shared.selectFile(plistPath.path, inFileViewerRootedAtPath: "")
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "folder")
                        Text("Reveal in Finder")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
            
            if service.domain.requiresRoot {
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
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch service.status {
        case .running:
            return .green
        case .loaded, .stopped:
            return .blue
        case .failed:
            return .red
        case .disabled:
            return .gray
        case .unloaded, .unknown:
            return .secondary
        }
    }
    
    private func performOperation(_ operation: @escaping () async -> Void) {
        Task {
            isOperationInProgress = true
            await operation()
            isOperationInProgress = false
        }
    }
}

#Preview {
    ServiceDetailView(
        service: LaunchService(
            label: "com.example.mydaemon",
            domain: .userAgents,
            plistPath: URL(fileURLWithPath: "/Users/test/Library/LaunchAgents/com.example.mydaemon.plist"),
            status: .running(pid: 1234),
            pid: 1234,
            programPath: "/usr/local/bin/mydaemon",
            programArguments: ["/usr/local/bin/mydaemon", "-v", "--config", "/etc/mydaemon.conf"],
            runAtLoad: true,
            keepAlive: true,
            standardOutPath: "/var/log/mydaemon.log",
            standardErrorPath: "/var/log/mydaemon.err"
        )
    )
    .environmentObject(ServiceMonitor())
    .frame(width: 480, height: 600)
}
