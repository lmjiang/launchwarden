import SwiftUI

struct LaunchItemListView: View {
    let items: [LaunchItem]
    @Binding var selectedItem: LaunchItem?
    let onToggle: (LaunchItem) -> Void

    var body: some View {
        if items.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                List(selection: $selectedItem) {
                    ForEach(items) { item in
                        LaunchItemRow(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onToggle: { onToggle(item) }
                        )
                        .tag(item)
                        .id(item.id)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.visible)
                    }
                }
                .listStyle(.plain)
                .onChange(of: selectedItem) { _, newValue in
                    if let item = newValue {
                        withAnimation {
                            proxy.scrollTo(item.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No Launch Items")
                .font(.title2)
                .fontWeight(.medium)

            Text("No launch items match your current filter or search.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LaunchItemListView(
        items: [
            LaunchItem(
                label: "com.apple.Safari.helper",
                path: "/Library/LaunchAgents/com.apple.Safari.helper.plist",
                type: .userAgent,
                isEnabled: true,
                isRunning: true
            ),
            LaunchItem(
                label: "com.docker.helper",
                path: "/Library/LaunchDaemons/com.docker.helper.plist",
                type: .systemDaemon,
                isEnabled: true,
                isRunning: false
            )
        ],
        selectedItem: .constant(nil),
        onToggle: { _ in }
    )
    .frame(width: 400, height: 300)
}
