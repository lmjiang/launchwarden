import SwiftUI

struct LaunchItemListView: View {
    let items: [LaunchItem]
    @Binding var selectedItem: LaunchItem?
    let onToggle: (LaunchItem) -> Void

    var body: some View {
        if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(items) { item in
                        LaunchItemRow(
                            item: item,
                            isSelected: selectedItem?.id == item.id,
                            onToggle: { onToggle(item) }
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedItem = item
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "tray")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.tertiary)
            }

            VStack(spacing: 6) {
                Text("No Launch Items")
                    .font(.system(size: 16, weight: .semibold))

                Text("No items match your current filter or search.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
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
    .frame(width: 450, height: 400)
}
