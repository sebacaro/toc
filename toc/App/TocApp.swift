import SwiftUI

@main
struct TocApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu-bar-only app — no scenes needed.
        // Preferences window is managed by PreferencesWindowController.
        Settings {
            EmptyView()
        }
    }
}
