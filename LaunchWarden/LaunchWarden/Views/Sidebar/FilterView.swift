import SwiftUI

struct FilterView: View {
    @Binding var searchText: String
    @Binding var showOnlyRunning: Bool
    @Binding var showOnlyFailed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Filter services...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            
            Menu {
                Toggle("Running Only", isOn: $showOnlyRunning)
                Toggle("Failed Only", isOn: $showOnlyFailed)
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(hasActiveFilters ? .accentColor : .secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var hasActiveFilters: Bool {
        showOnlyRunning || showOnlyFailed
    }
}

#Preview {
    FilterView(
        searchText: .constant(""),
        showOnlyRunning: .constant(false),
        showOnlyFailed: .constant(false)
    )
}
