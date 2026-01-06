import SwiftUI

struct LogViewerView: View {
    let service: LaunchService
    
    @State private var stdoutContent: String = ""
    @State private var stderrContent: String = ""
    @State private var selectedLog: LogType = .stdout
    @State private var isLoading = false
    @State private var autoRefresh = false
    @State private var refreshTimer: Timer?
    
    enum LogType: String, CaseIterable {
        case stdout = "Standard Output"
        case stderr = "Standard Error"
        case system = "System Log"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("Log", selection: $selectedLog) {
                    ForEach(LogType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 350)
                
                Spacer()
                
                Toggle("Auto-refresh", isOn: $autoRefresh)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                Button {
                    loadLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Log content
            if isLoading {
                ProgressView("Loading logs...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if currentLogContent.isEmpty {
                noLogsView
            } else {
                ScrollView {
                    Text(currentLogContent)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(nsColor: .textBackgroundColor))
            }
        }
        .onAppear {
            loadLogs()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .onChange(of: autoRefresh) { _, newValue in
            if newValue {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
        .onChange(of: selectedLog) { _, _ in
            loadLogs()
        }
    }
    
    // MARK: - Views
    
    private var noLogsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Logs Available")
                .font(.headline)
            
            switch selectedLog {
            case .stdout:
                if service.standardOutPath == nil {
                    Text("This service doesn't have a StandardOutPath configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Log file may be empty or inaccessible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .stderr:
                if service.standardErrorPath == nil {
                    Text("This service doesn't have a StandardErrorPath configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Log file may be empty or inaccessible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            case .system:
                Text("Use Console.app for complete system logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Open Console") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Console.app"))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Methods
    
    private var currentLogContent: String {
        switch selectedLog {
        case .stdout:
            return stdoutContent
        case .stderr:
            return stderrContent
        case .system:
            return stdoutContent // System logs loaded into stdout
        }
    }
    
    private func loadLogs() {
        isLoading = true
        
        Task {
            switch selectedLog {
            case .stdout:
                if let path = service.standardOutPath {
                    stdoutContent = readLogFile(at: path)
                } else {
                    stdoutContent = ""
                }
            case .stderr:
                if let path = service.standardErrorPath {
                    stderrContent = readLogFile(at: path)
                } else {
                    stderrContent = ""
                }
            case .system:
                // Query system log for this service
                stdoutContent = await querySystemLog()
            }
            
            isLoading = false
        }
    }
    
    private func readLogFile(at path: String) -> String {
        let url = URL(fileURLWithPath: path)
        
        guard FileManager.default.fileExists(atPath: path) else {
            return ""
        }
        
        do {
            // Read last 100KB to avoid loading huge files
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer { try? fileHandle.close() }
            
            let fileSize = try fileHandle.seekToEnd()
            let readSize = min(fileSize, 100 * 1024) // 100KB max
            
            if readSize < fileSize {
                try fileHandle.seek(toOffset: fileSize - readSize)
            } else {
                try fileHandle.seek(toOffset: 0)
            }
            
            if let data = try fileHandle.readToEnd(),
               let content = String(data: data, encoding: .utf8) {
                return content
            }
        } catch {
            return "Error reading log file: \(error.localizedDescription)"
        }
        
        return ""
    }
    
    private func querySystemLog() async -> String {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "show",
            "--predicate", "subsystem == '\(service.label)' OR process == '\(service.displayName)'",
            "--last", "1h",
            "--style", "compact"
        ]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return "Error querying system log: \(error.localizedDescription)"
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            loadLogs()
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

#Preview {
    LogViewerView(
        service: LaunchService(
            label: "com.example.test",
            domain: .userAgents,
            standardOutPath: "/var/log/test.log",
            standardErrorPath: "/var/log/test.err"
        )
    )
}
