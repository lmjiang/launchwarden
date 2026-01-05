import SwiftUI

@main
struct LaunchWardenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandGroup(after: .appInfo) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshLaunchItems, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let refreshLaunchItems = Notification.Name("refreshLaunchItems")
}
