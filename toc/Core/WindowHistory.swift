import Cocoa

@MainActor
final class WindowHistory {
    static let shared = WindowHistory()

    private struct Entry {
        let window: AccessibilityElement
        let frame: CGRect
    }
    private var entries: [Entry] = []

    init() {}

    func recordChange(window: AccessibilityElement, originalFrame: CGRect, actualFrame: CGRect?) {
        guard let actualFrame, actualFrame != originalFrame else { return }
        save(window: window, frame: originalFrame)
    }

    func save(window: AccessibilityElement, frame: CGRect) {
        guard self.frame(for: window) == nil else { return }
        if entries.count >= 128 { entries.removeFirst() }
        entries.append(Entry(window: window, frame: frame))
    }

    func frame(for window: AccessibilityElement) -> CGRect? {
        entries.first { $0.window.isSameWindow(as: window) }?.frame
    }

    func remove(window: AccessibilityElement) {
        entries.removeAll { $0.window.isSameWindow(as: window) }
    }
}
