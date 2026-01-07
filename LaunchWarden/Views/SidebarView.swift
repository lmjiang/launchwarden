import SwiftUI

struct SidebarView: View {
    @Binding var selectedFilter: SidebarFilter
    let itemCounts: [SidebarFilter: Int]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("LaunchWarden")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text("\(itemCounts[.all] ?? 0) Services")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 12)

            // Filter List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(SidebarFilter.allCases, id: \.self) { filter in
                        SidebarRow(
                            filter: filter,
                            count: itemCounts[filter] ?? 0,
                            isSelected: selectedFilter == filter
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }

            Spacer()
        }
        .frame(minWidth: 180)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}

struct SidebarRow: View {
    let filter: SidebarFilter
    let count: Int
    let isSelected: Bool

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? iconColor.opacity(0.15) : Color.clear)
                    .frame(width: 28, height: 28)

                Image(systemName: filter.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? iconColor : .secondary)
            }

            Text(filter.title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)

            Spacer()

            Text("\(count)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? iconColor : Color.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    Capsule()
                        .fill(isSelected ? iconColor.opacity(0.12) : Color.primary.opacity(0.05))
                }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.04)
        }
        return Color.clear
    }

    private var iconColor: Color {
        switch filter {
        case .all:
            return .accentColor
        case .userAgent:
            return .blue
        case .systemAgent:
            return .orange
        case .systemDaemon:
            return .purple
        }
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
    .frame(width: 200, height: 400)
}
