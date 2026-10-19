import Cocoa

enum AppRuntime {
    static func isRunningTests(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        ["XCTestConfigurationFilePath", "XCTestBundlePath", "XCTestSessionIdentifier"]
            .contains { environment[$0] != nil }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let menuBarManager = MenuBarManager()
    private var startedServices = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The unit-test host must not request TCC permission or register global input.
        guard !AppRuntime.isRunningTests(), NSClassFromString("XCTestCase") == nil else { return }
        startedServices = true

        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.snappingEnabled: true,
            UserDefaultsKeys.snapEdgeThreshold: 8.0,
            UserDefaultsKeys.excludedApplications: ""
        ])

        // Only prompt for accessibility if not already trusted
        if !AccessibilityPermission.isTrusted {
            AccessibilityPermission.promptForAccess()
        }

        // Set up menu bar
        menuBarManager.setup()

        // Register keyboard shortcuts
        ShortcutManager.shared.registerAll()

        // Start drag-to-edge snapping if enabled
        if UserDefaults.standard.bool(forKey: UserDefaultsKeys.snappingEnabled) {
            SnapManager.shared.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard startedServices else { return }
        SnapManager.shared.stop()
    }
}
