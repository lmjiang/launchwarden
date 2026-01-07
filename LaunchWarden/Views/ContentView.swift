import SwiftUI

struct ContentView: View {
    @State private var viewModel = LaunchItemsViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedFilter: $viewModel.selectedFilter,
                itemCounts: viewModel.itemCounts
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } content: {
            VStack(spacing: 0) {
                // Search bar with X button
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)

                    TextField("Search services...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isSearchFocused)
                    
                    // Clear button (X)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSearchFocused ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
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
            .navigationSplitViewColumnWidth(min: 420, ideal: 500, max: 600)
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
                
                // Hidden button for Cmd+F search shortcut
                Button {
                    isSearchFocused = true
                } label: {
                    EmptyView()
                }
                .keyboardShortcut("f", modifiers: .command)
                .hidden()
            }
        }
        .onKeyPress(.escape) {
            if isSearchFocused {
                viewModel.searchText = ""
                isSearchFocused = false
                return .handled
            }
            return .ignored
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
