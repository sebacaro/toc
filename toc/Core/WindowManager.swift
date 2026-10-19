import Cocoa
import OSLog

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    @Published private(set) var lastStatus: String?
    private let logger = Logger(subsystem: "com.seba.toc", category: "WindowMovement")

    private init() {}

    func execute(_ action: WindowAction) {
        guard AccessibilityPermission.isTrusted else {
            report("Grant Accessibility access to Toc in System Settings.")
            AccessibilityPermission.promptForAccess()
            return
        }
        guard let window = AccessibilityElement.focusedWindow(), let current = window.frame else {
            report("The active application has no accessible window.")
            return
        }
        guard !WindowPreferences.isExcluded(bundleIdentifier: window.bundleIdentifier) else { return }

        switch action {
        case .restore:
            guard let saved = WindowHistory.shared.frame(for: window),
                  let screen = ScreenManager.shared.screenContaining(rect: saved) else { return }
            if move(window, to: saved, visibleFrame: screen.flippedVisibleFrame) {
                WindowHistory.shared.remove(window: window)
            }
        case .nextDisplay, .previousDisplay:
            guard let source = ScreenManager.shared.screenContaining(rect: current),
                  let target = ScreenManager.shared.adjacentScreen(to: source, direction: action == .nextDisplay ? .next : .previous),
                  target != source else { return }
            let from = source.flippedVisibleFrame
            let to = target.flippedVisibleFrame
            guard from.width > 0, from.height > 0 else { return }
            let destination = CGRect(x: to.minX + (current.minX - from.minX) / from.width * to.width,
                                     y: to.minY + (current.minY - from.minY) / from.height * to.height,
                                     width: current.width / from.width * to.width,
                                     height: current.height / from.height * to.height)
            move(window, to: destination, visibleFrame: to, originalFrame: current)
        default:
            guard let screen = ScreenManager.shared.screenContaining(rect: current),
                  let calculation = WindowCalculationFactory.calculation(for: action) else { return }
            let visible = screen.flippedVisibleFrame
            move(window, to: calculation.calculateRect(visibleFrame: visible, windowFrame: current), visibleFrame: visible, originalFrame: current)
        }
    }

    func executeSnap(_ zone: SnapZone, window: AccessibilityElement) {
        guard AccessibilityPermission.isTrusted,
              !WindowPreferences.isExcluded(bundleIdentifier: window.bundleIdentifier),
              let current = window.frame else { return }
        move(window, to: zone.rect, visibleFrame: zone.visibleFrame, originalFrame: current)
    }

    @discardableResult
    private func move(_ window: AccessibilityElement, to target: CGRect, visibleFrame: CGRect, originalFrame: CGRect? = nil) -> Bool {
        let wasEnhancedUI = window.isEnhancedUserInterfaceEnabled == true
        if wasEnhancedUI { window.isEnhancedUserInterfaceEnabled = false }
        defer {
            if wasEnhancedUI { window.isEnhancedUserInterfaceEnabled = true }
        }

        let result = WindowFrameWriter.apply(target, to: window, visibleFrame: visibleFrame)
        if let originalFrame {
            let actualFrame: CGRect?
            switch result {
            case .success(let outcome): actualFrame = outcome.actualFrame
            case .failure: actualFrame = window.frame
            }
            WindowHistory.shared.recordChange(window: window, originalFrame: originalFrame, actualFrame: actualFrame)
        }
        switch result {
        case .success(let outcome):
            lastStatus = outcome.wasConstrained ? "The application limited the requested size or position." : nil
            return true
        case .failure(let failure):
            switch failure {
            case .notResizable: report("This window does not support resizing.")
            case .notMovable: report("This window does not support moving.")
            case .invalidFrame: report("The requested window geometry is invalid.")
            case .unavailable: report("The window is no longer accessible. Try again with an active window.")
            case .accessibility(let error):
                report("The application refused the window change (AX \(error.rawValue)). Try again or check Accessibility access.")
            }
            return false
        }
    }

    private func report(_ message: String) {
        lastStatus = message
        logger.error("\(message, privacy: .public)")
        NSSound.beep()
    }
}
