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
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } content: {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)

                    TextField("Search services...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // List
                LaunchItemListView(
                    items: viewModel.filteredItems,
                    selectedItem: $viewModel.selectedItem,
                    onToggle: { item in
                        Task {
                            await viewModel.toggleEnabled(for: item)
                        }
                    }
                )
            }
            .navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 520)
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
            .navigationSplitViewColumnWidth(min: 380, ideal: 460)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                }

                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .medium))
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.isLoading)
                .help("Refresh (Cmd+R)")
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
        .frame(width: 1100, height: 700)
}
