import SwiftUI

@main
struct LaunchWardenApp: App {
    var body: some Scene {
        Window("LaunchWarden", id: "main") {
            ContentView()
        }
        .windowStyle(.automatic)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1280, height: 750)
        .commands {
            // Disable new window/tab
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .windowArrangement) {}

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
