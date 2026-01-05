import SwiftUI

struct ContentView: View {
    @State private var viewModel = LaunchItemsViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedFilter: $viewModel.selectedFilter,
                itemCounts: viewModel.itemCounts
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } content: {
            LaunchItemListView(
                items: viewModel.filteredItems,
                selectedItem: $viewModel.selectedItem,
                onToggle: { item in
                    Task {
                        await viewModel.toggleEnabled(for: item)
                    }
                }
            )
            .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 500)
            .searchable(text: $viewModel.searchText, prompt: "Search launch items...")
        } detail: {
            DetailView(
                item: viewModel.selectedItem,
                onToggle: { item in
                    Task {
                        await viewModel.toggleEnabled(for: item)
                    }
                },
                onRevealInFinder: { item in
                    viewModel.revealInFinder(item: item)
                }
            )
            .navigationSplitViewColumnWidth(min: 350, ideal: 450)
        }
        .navigationTitle("LaunchWarden")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadItems()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 600)
}
