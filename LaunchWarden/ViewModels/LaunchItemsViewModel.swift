import Foundation
import SwiftUI

@MainActor
@Observable
final class LaunchItemsViewModel {
    var items: [LaunchItem] = []
    var selectedFilter: SidebarFilter = .all
    var selectedItem: LaunchItem?
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false

    private let service = LaunchctlService.shared

    var filteredItems: [LaunchItem] {
        var result = items

        if let type = selectedFilter.itemType {
            result = result.filter { $0.type == type }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.label.lowercased().contains(query) ||
                $0.displayName.lowercased().contains(query) ||
                $0.vendor.lowercased().contains(query)
            }
        }

        return result
    }

    var itemCounts: [SidebarFilter: Int] {
        var counts: [SidebarFilter: Int] = [:]
        counts[.all] = items.count
        counts[.userAgent] = items.filter { $0.type == .userAgent }.count
        counts[.systemAgent] = items.filter { $0.type == .systemAgent }.count
        counts[.systemDaemon] = items.filter { $0.type == .systemDaemon }.count
        return counts
    }

    func loadItems() async {
        isLoading = true
        errorMessage = nil

        items = await service.fetchAllItems()

        isLoading = false
    }

    func refresh() async {
        await loadItems()

        if let selected = selectedItem,
           let updated = items.first(where: { $0.id == selected.id }) {
            selectedItem = updated
        } else if let selected = selectedItem,
                  let updated = items.first(where: { $0.label == selected.label }) {
            selectedItem = updated
        }
    }

    func toggleEnabled(for item: LaunchItem) async {
        let result: Result<Void, LaunchctlError>

        if item.isEnabled {
            result = await service.disable(item: item)
        } else {
            result = await service.enable(item: item)
        }

        switch result {
        case .success:
            await refresh()
        case .failure(let error):
            if case .userCancelled = error {
                return
            }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func enable(item: LaunchItem) async {
        let result = await service.enable(item: item)

        switch result {
        case .success:
            await refresh()
        case .failure(let error):
            if case .userCancelled = error {
                return
            }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func disable(item: LaunchItem) async {
        let result = await service.disable(item: item)

        switch result {
        case .success:
            await refresh()
        case .failure(let error):
            if case .userCancelled = error {
                return
            }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func revealInFinder(item: LaunchItem) {
        Task {
            await service.revealInFinder(item: item)
        }
    }
}
