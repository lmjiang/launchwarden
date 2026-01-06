import SwiftUI

struct SidebarView: View {
    @Binding var selectedDomain: ServiceDomain?
    @EnvironmentObject var serviceMonitor: ServiceMonitor
    @AppStorage("showSystemServices") private var showSystemServices: Bool = false
    
    var body: some View {
        List(selection: $selectedDomain) {
            Section("User Services") {
                SidebarRow(domain: .userAgents, count: serviceCount(for: .userAgents))
                    .tag(ServiceDomain.userAgents)
            }
            
            Section("Global Services") {
                SidebarRow(domain: .globalAgents, count: serviceCount(for: .globalAgents))
                    .tag(ServiceDomain.globalAgents)
                SidebarRow(domain: .globalDaemons, count: serviceCount(for: .globalDaemons))
                    .tag(ServiceDomain.globalDaemons)
            }
            
            if showSystemServices {
                Section("System Services") {
                    SidebarRow(domain: .systemAgents, count: serviceCount(for: .systemAgents))
                        .tag(ServiceDomain.systemAgents)
                    SidebarRow(domain: .systemDaemons, count: serviceCount(for: .systemDaemons))
                        .tag(ServiceDomain.systemDaemons)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    if let lastRefresh = serviceMonitor.lastRefresh {
                        Text("Updated \(lastRefresh, style: .relative) ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if serviceMonitor.isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(.bar)
        }
    }
    
    private func serviceCount(for domain: ServiceDomain) -> Int {
        serviceMonitor.services(for: domain).count
    }
}

struct SidebarRow: View {
    let domain: ServiceDomain
    let count: Int
    
    var body: some View {
        Label {
            HStack {
                Text(domain.rawValue)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        } icon: {
            Image(systemName: domain.icon)
                .foregroundColor(domain.isSystem ? .secondary : .accentColor)
        }
    }
}

#Preview {
    SidebarView(selectedDomain: .constant(.userAgents))
        .environmentObject(ServiceMonitor())
}
