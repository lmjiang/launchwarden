import SwiftUI

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("An Error Occurred")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
                .textSelection(.enabled)
            
            if let retryAction = retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ErrorView(
        error: NSError(
            domain: "LaunchWarden",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load services. Please check your permissions."]
        ),
        retryAction: {}
    )
}
