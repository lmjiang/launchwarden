import SwiftUI

struct SidebarView: View {
    @Binding var selectedFilter: SidebarFilter
    let itemCounts: [SidebarFilter: Int]

    var body: some View {
        List(selection: $selectedFilter) {
            Section("Categories") {
                ForEach(SidebarFilter.allCases, id: \.self) { filter in
                    SidebarRow(filter: filter, count: itemCounts[filter] ?? 0)
                        .tag(filter)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}

struct SidebarRow: View {
    let filter: SidebarFilter
    let count: Int

    var body: some View {
        HStack {
            Label(filter.title, systemImage: filter.icon)

            Spacer()

            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SidebarView(
        selectedFilter: .constant(.all),
        itemCounts: [
            .all: 42,
            .userAgent: 15,
            .systemAgent: 12,
            .systemDaemon: 15
        ]
    )
    .frame(width: 220)
}
