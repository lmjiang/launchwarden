import SwiftUI

struct ServiceListView: View {
    let selectedDomain: ServiceDomain?
    @Binding var searchText: String
    
    @EnvironmentObject var serviceMonitor: ServiceMonitor
    @State private var showOnlyRunning: Bool = false
    @State private var showOnlyFailed: Bool = false
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case status = "Status"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("\(filteredServices.count) services")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                
                Menu {
                    Toggle("Running Only", isOn: $showOnlyRunning)
                    Toggle("Failed Only", isOn: $showOnlyFailed)
                    Divider()
                    Button("Clear Filters") {
                        showOnlyRunning = false
                        showOnlyFailed = false
                    }
                } label: {
                    Image(systemName: hasActiveFilters 
                        ? "line.3.horizontal.decrease.circle.fill" 
                        : "line.3.horizontal.decrease.circle")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 30)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Service list
            if filteredServices.isEmpty {
                emptyStateView
            } else {
                List(selection: $serviceMonitor.selectedService) {
                    ForEach(sortedServices) { service in
                        ServiceRowView(
                            service: service,
                            isSelected: serviceMonitor.selectedService == service
                        )
                        .tag(service)
                        .contextMenu {
                            serviceContextMenu(for: service)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 300)
    }
    
    // MARK: - Computed Properties
    
    private var filteredServices: [LaunchService] {
        var result = serviceMonitor.filteredServices(
            domain: selectedDomain,
            searchText: searchText
        )
        
        if showOnlyRunning {
            result = result.filter { $0.status.isActive }
        }
        
        if showOnlyFailed {
            result = result.filter { $0.status.hasError }
        }
        
        return result
    }
    
    private var sortedServices: [LaunchService] {
        switch sortOrder {
        case .name:
            return filteredServices.sorted { $0.label < $1.label }
        case .status:
            return filteredServices.sorted { 
                $0.status.isActive && !$1.status.isActive
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        showOnlyRunning || showOnlyFailed
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Services Found")
                .font(.headline)
            
            if !searchText.isEmpty || hasActiveFilters {
                Text("Try adjusting your search or filters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("Clear Filters") {
                    searchText = ""
                    showOnlyRunning = false
                    showOnlyFailed = false
                }
                .buttonStyle(.link)
            } else if let domain = selectedDomain {
                Text("No services in \(domain.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func serviceContextMenu(for service: LaunchService) -> some View {
        if service.status.isActive {
            Button {
                Task { await serviceMonitor.stopService(service) }
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
        } else {
            Button {
                Task { await serviceMonitor.startService(service) }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
        }
        
        Divider()
        
        if case .unloaded = service.status {
            Button {
                Task { await serviceMonitor.loadService(service) }
            } label: {
                Label("Load", systemImage: "arrow.up.circle")
            }
        } else {
            Button {
                Task { await serviceMonitor.unloadService(service) }
            } label: {
                Label("Unload", systemImage: "arrow.down.circle")
            }
        }
        
        Divider()
        
        if let plistPath = service.plistPath {
            Button {
                NSWorkspace.shared.selectFile(plistPath.path, inFileViewerRootedAtPath: "")
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }
        }
        
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(service.label, forType: .string)
        } label: {
            Label("Copy Label", systemImage: "doc.on.doc")
        }
    }
}

#Preview {
    ServiceListView(
        selectedDomain: .userAgents,
        searchText: .constant("")
    )
    .environmentObject(ServiceMonitor())
}
