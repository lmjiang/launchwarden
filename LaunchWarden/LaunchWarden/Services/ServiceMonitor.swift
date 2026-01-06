import Foundation
import Combine
import SwiftUI

/// Monitors and manages launchd services
@MainActor
class ServiceMonitor: ObservableObject {
    @Published var services: [LaunchService] = []
    @Published var selectedService: LaunchService?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var lastRefresh: Date?
    
    @AppStorage("showSystemServices") private var showSystemServices: Bool = false
    
    private let launchctl = LaunchctlManager()
    private let fileWatcher = FileWatcher()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupFileWatcher()
    }
    
    private func setupFileWatcher() {
        // Watch launchd directories for changes
        let paths = ServiceDomain.allCases.map { $0.path }
        fileWatcher.watch(paths: paths)
        
        fileWatcher.$lastChange
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.refreshServices()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Refresh the list of all services
    func refreshServices() async {
        isLoading = true
        error = nil
        
        do {
            // Get loaded services from launchctl
            let loadedServices = try await launchctl.listServices()
            
            // Scan plist files from each domain
            var allServices: [LaunchService] = []
            let domainsToScan: [ServiceDomain] = showSystemServices 
                ? ServiceDomain.allCases 
                : [.userAgents, .globalAgents, .globalDaemons]
            
            for domain in domainsToScan {
                let plistFiles = PlistParser.getPlistFiles(in: domain.path)
                
                for plistURL in plistFiles {
                    do {
                        var service = try PlistParser.parse(url: plistURL, domain: domain)
                        
                        // Update status from launchctl list
                        if let info = loadedServices[service.label] {
                            if let pid = info.pid {
                                service.status = .running(pid: pid)
                                service.pid = pid
                            } else if let exitCode = info.status, exitCode != 0 {
                                service.status = .failed(exitCode: exitCode)
                                service.lastExitStatus = exitCode
                            } else {
                                service.status = .loaded
                            }
                        } else {
                            service.status = service.disabled ? .disabled : .unloaded
                        }
                        
                        allServices.append(service)
                    } catch {
                        // Skip services with invalid plists
                        print("Failed to parse \(plistURL.lastPathComponent): \(error)")
                    }
                }
            }
            
            // Add loaded services that don't have plist files (system services)
            if showSystemServices {
                for (label, info) in loadedServices {
                    if !allServices.contains(where: { $0.label == label }) {
                        var status: ServiceStatus
                        if let pid = info.pid {
                            status = .running(pid: pid)
                        } else if let exitCode = info.status, exitCode != 0 {
                            status = .failed(exitCode: exitCode)
                        } else {
                            status = .loaded
                        }
                        
                        let service = LaunchService(
                            label: label,
                            domain: label.hasPrefix("com.apple.") ? .systemDaemons : .userAgents,
                            status: status,
                            pid: info.pid,
                            lastExitStatus: info.status
                        )
                        allServices.append(service)
                    }
                }
            }
            
            // Sort by label
            services = allServices.sorted { $0.label < $1.label }
            lastRefresh = Date()
            
            // Update selected service if it still exists
            if let selected = selectedService {
                selectedService = services.first { $0.label == selected.label }
            }
            
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Get services for a specific domain
    func services(for domain: ServiceDomain?) -> [LaunchService] {
        guard let domain = domain else { return services }
        return services.filter { $0.domain == domain }
    }
    
    /// Filter services by search text
    func filteredServices(domain: ServiceDomain?, searchText: String) -> [LaunchService] {
        var result = services(for: domain)
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.label.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query)
            }
        }
        
        return result
    }
    
    /// Start a service (enable + bootstrap)
    func startService(_ service: LaunchService) async {
        guard let plistPath = service.plistPath else {
            print("[LaunchWarden] Cannot start service without plist path")
            return
        }
        do {
            print("[LaunchWarden] Starting service: \(service.label)")
            try await launchctl.start(label: service.label, plistPath: plistPath, domain: service.domain)
            try? await Task.sleep(nanoseconds: 500_000_000)
            await refreshServices()
        } catch {
            print("[LaunchWarden] Start failed: \(error)")
            self.error = error
        }
    }
    
    /// Stop a service (bootout + disable)
    func stopService(_ service: LaunchService) async {
        do {
            print("[LaunchWarden] Stopping service: \(service.label) in domain \(service.domain.rawValue)")
            try await launchctl.stop(label: service.label, domain: service.domain)
            try? await Task.sleep(nanoseconds: 500_000_000)
            await refreshServices()
        } catch {
            print("[LaunchWarden] Stop failed: \(error)")
            self.error = error
        }
    }
    
    /// Load a service (same as start)
    func loadService(_ service: LaunchService) async {
        await startService(service)
    }
    
    /// Unload a service (same as stop)
    func unloadService(_ service: LaunchService) async {
        await stopService(service)
    }
    
    /// Enable a service
    func enableService(_ service: LaunchService) async {
        guard let plistPath = service.plistPath else { return }
        do {
            try await launchctl.enable(label: service.label, plistPath: plistPath, domain: service.domain)
            await refreshServices()
        } catch {
            self.error = error
        }
    }
    
    /// Disable a service
    func disableService(_ service: LaunchService) async {
        do {
            try await launchctl.disable(label: service.label, domain: service.domain)
            await refreshServices()
        } catch {
            self.error = error
        }
    }
    
    /// Get blame information for a service
    func getBlame(for service: LaunchService) async -> String? {
        let result = await launchctl.blame(label: service.label, domain: service.domain)
        return result.isEmpty ? nil : result
    }
}
