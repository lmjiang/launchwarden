import SwiftUI

@main
struct LaunchWardenApp: App {
    @StateObject private var serviceMonitor = ServiceMonitor()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceMonitor)
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Services") {
                Button("Refresh All") {
                    Task {
                        await serviceMonitor.refreshServices()
                    }
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Start Selected") {
                    if let service = serviceMonitor.selectedService {
                        Task {
                            await serviceMonitor.startService(service)
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(serviceMonitor.selectedService == nil)
                
                Button("Stop Selected") {
                    if let service = serviceMonitor.selectedService {
                        Task {
                            await serviceMonitor.stopService(service)
                        }
                    }
                }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(serviceMonitor.selectedService == nil)
            }
        }
        
        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

struct SettingsView: View {
    @AppStorage("refreshInterval") private var refreshInterval: Double = 5.0
    @AppStorage("showSystemServices") private var showSystemServices: Bool = false
    
    var body: some View {
        Form {
            Section {
                Slider(value: $refreshInterval, in: 1...30, step: 1) {
                    Text("Refresh Interval")
                }
                Text("\(Int(refreshInterval)) seconds")
                    .foregroundColor(.secondary)
            } header: {
                Text("General")
            }
            
            Section {
                Toggle("Show System Services", isOn: $showSystemServices)
                Text("System services are read-only and require SIP to be disabled to modify.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Display")
            }
        }
        .padding()
        .frame(width: 400)
    }
}
