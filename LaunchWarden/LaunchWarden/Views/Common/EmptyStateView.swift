import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    VStack {
        EmptyStateView(
            icon: "tray",
            title: "No Services",
            message: "No services found in this domain."
        )
        
        Divider()
        
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try adjusting your search criteria.",
            action: {},
            actionLabel: "Clear Filters"
        )
    }
}
