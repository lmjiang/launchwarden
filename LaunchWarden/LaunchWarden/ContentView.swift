import SwiftUI

struct ContentView: View {
    @EnvironmentObject var serviceMonitor: ServiceMonitor
    @State private var selectedDomain: ServiceDomain? = .userAgents
    @State private var searchText: String = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedDomain: $selectedDomain)
        } content: {
            ServiceListView(
                selectedDomain: selectedDomain,
                searchText: $searchText
            )
        } detail: {
            Group {
                if let service = serviceMonitor.selectedService {
                    ServiceDetailView(service: service)
                } else {
                    EmptyStateView(
                        icon: "gear.circle",
                        title: "No Service Selected",
                        message: "Select a service from the list to view its details and controls."
                    )
                }
            }
            .animation(.easeInOut(duration: 0.2), value: serviceMonitor.selectedService?.id)
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Filter services...")
        .navigationTitle(selectedDomain?.rawValue ?? "LaunchWarden")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if serviceMonitor.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                }
                
                Button {
                    Task {
                        await serviceMonitor.refreshServices()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(serviceMonitor.isLoading)
                .help("Refresh (⌘R)")
            }
        }
        .task {
            await serviceMonitor.refreshServices()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ServiceMonitor())
}
