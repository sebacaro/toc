import Cocoa
import Testing
@testable import toc

@MainActor
@Suite("Window restore history")
struct WindowHistoryTests {
    @Test("A rejected command does not replace the next real restore point")
    func rejectedCommand() {
        let history = WindowHistory()
        let window = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let rejected = CGRect(x: 100, y: 100, width: 800, height: 600)
        history.recordChange(window: window, originalFrame: rejected, actualFrame: rejected)
        #expect(history.frame(for: window) == nil)
        let movedManually = CGRect(x: 200, y: 150, width: 800, height: 600)
        history.recordChange(window: window, originalFrame: movedManually, actualFrame: CGRect(x: 0, y: 0, width: 500, height: 500))
        #expect(history.frame(for: window) == movedManually)
    }

    @Test("A partial AX failure can still be undone")
    func partialChange() {
        let history = WindowHistory()
        let window = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let original = CGRect(x: 100, y: 100, width: 800, height: 600)
        history.recordChange(window: window, originalFrame: original, actualFrame: CGRect(x: 100, y: 100, width: 500, height: 500))
        #expect(history.frame(for: window) == original)
    }

    @Test("Repeated commands preserve the original frame")
    func originalFrame() {
        let history = WindowHistory()
        let window = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let original = CGRect(x: 100, y: 100, width: 800, height: 600)
        history.save(window: window, frame: original)
        history.save(window: window, frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        #expect(history.frame(for: window) == original)
    }

    @Test("Public AX equality recognizes another reference to the same element")
    func sameElement() {
        let history = WindowHistory()
        let first = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let second = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let original = CGRect(x: 100, y: 100, width: 800, height: 600)
        history.save(window: first, frame: original)
        #expect(history.frame(for: second) == original)
        history.remove(window: second)
        #expect(history.frame(for: first) == nil)
    }

    @Test("Looking up a restore does not consume it before a successful move")
    func retainedUntilRemoved() {
        let history = WindowHistory()
        let window = AccessibilityElement(AXUIElementCreateApplication(getpid()))
        let original = CGRect(x: 100, y: 100, width: 800, height: 600)
        history.save(window: window, frame: original)
        #expect(history.frame(for: window) == original)
        #expect(history.frame(for: window) == original)
        history.remove(window: window)
        #expect(history.frame(for: window) == nil)
    }
}
