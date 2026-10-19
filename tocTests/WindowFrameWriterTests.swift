import Cocoa
import Testing
@testable import toc

@MainActor
@Suite("Checked window movement")
struct WindowFrameWriterTests {
    private let screen = CGRect(x: -1200, y: 40, width: 1200, height: 800)

    @Test("A command reaches its requested frame")
    func exactFrame() throws {
        let window = TestFrameAccess(frame: CGRect(x: -1100, y: 100, width: 700, height: 500))
        let target = CGRect(x: -1200, y: 40, width: 600, height: 800)
        let outcome = try WindowFrameWriter.apply(target, to: window, visibleFrame: screen).get()
        #expect(window.frame == target)
        #expect(outcome.actualFrame == target)
        #expect(!outcome.wasConstrained)
    }

    @Test("Consecutive commands leave the last requested geometry")
    func consecutiveCommands() throws {
        let window = TestFrameAccess(frame: CGRect(x: -1100, y: 100, width: 700, height: 500))
        for target in [CGRect(x: -1200, y: 40, width: 600, height: 800), CGRect(x: -600, y: 40, width: 600, height: 800), screen] {
            _ = try WindowFrameWriter.apply(target, to: window, visibleFrame: screen).get()
        }
        #expect(window.frame == screen)
    }

    @Test("A minimum-size window stays aligned inside the selected screen")
    func minimumSize() throws {
        let window = TestFrameAccess(frame: CGRect(x: -1100, y: 100, width: 900, height: 600))
        window.minimumSize = CGSize(width: 800, height: 600)
        let target = CGRect(x: -600, y: 40, width: 600, height: 800)
        let outcome = try WindowFrameWriter.apply(target, to: window, visibleFrame: screen).get()
        #expect(outcome.wasConstrained)
        #expect(outcome.actualFrame == CGRect(x: -800, y: 40, width: 800, height: 800))
        #expect(screen.contains(outcome.actualFrame))
    }

    @Test("AX write errors are returned instead of reported as success")
    func writeFailure() {
        let original = CGRect(x: -1100, y: 100, width: 700, height: 500)
        let window = TestFrameAccess(frame: original)
        window.sizeError = .cannotComplete
        let result = WindowFrameWriter.apply(screen, to: window, visibleFrame: screen)
        guard case .failure(.accessibility(let error)) = result else {
            Issue.record("Expected an AX failure")
            return
        }
        #expect(error == .cannotComplete)
        #expect(window.frame == original)
    }

    @Test("An unsupported resize is refused before moving the window")
    func notResizable() {
        let original = CGRect(x: -1100, y: 100, width: 700, height: 500)
        let window = TestFrameAccess(frame: original)
        window.isSizeSettable = false
        #expect(WindowFrameWriter.apply(screen, to: window, visibleFrame: screen) == .failure(.notResizable))
        #expect(window.frame == original)
    }

    @Test("Non-finite geometry is rejected without AX writes")
    func invalidGeometry() {
        let original = CGRect(x: -1100, y: 100, width: 700, height: 500)
        let window = TestFrameAccess(frame: original)
        let invalid = CGRect(x: CGFloat.infinity, y: 0, width: 300, height: 300)
        #expect(WindowFrameWriter.apply(invalid, to: window, visibleFrame: screen) == .failure(.invalidFrame))
        #expect(window.frame == original)
    }

    @Test("An off-screen restore is fitted to an available screen")
    func offscreenFrame() throws {
        let window = TestFrameAccess(frame: CGRect(x: -1100, y: 100, width: 700, height: 500))
        let outcome = try WindowFrameWriter.apply(CGRect(x: 4000, y: -2000, width: 600, height: 400), to: window, visibleFrame: screen).get()
        #expect(outcome.actualFrame == CGRect(x: -600, y: 40, width: 600, height: 400))
        #expect(screen.contains(outcome.actualFrame))
    }

    @Test("Centering a fixed-size window does not require resize support")
    func moveWithoutResize() throws {
        let window = TestFrameAccess(frame: CGRect(x: -1200, y: 40, width: 700, height: 500))
        window.isSizeSettable = false
        let target = CGRect(x: -950, y: 190, width: 700, height: 500)
        let outcome = try WindowFrameWriter.apply(target, to: window, visibleFrame: screen).get()
        #expect(outcome.actualFrame == target)
    }

    @Test("A position write error remains a failure")
    func positionFailure() {
        let window = TestFrameAccess(frame: CGRect(x: -1100, y: 100, width: 700, height: 500))
        window.positionError = .invalidUIElement
        #expect(WindowFrameWriter.apply(screen, to: window, visibleFrame: screen) == .failure(.accessibility(.invalidUIElement)))
    }

    @Test("A window larger than the display keeps its top-left accessible")
    func minimumLargerThanScreen() throws {
        let window = TestFrameAccess(frame: screen)
        window.minimumSize = CGSize(width: 1600, height: 1000)
        let outcome = try WindowFrameWriter.apply(screen, to: window, visibleFrame: screen).get()
        #expect(outcome.wasConstrained)
        #expect(outcome.actualFrame.origin == screen.origin)
        #expect(outcome.actualFrame.size == window.minimumSize)
    }
}

@MainActor
private final class TestFrameAccess: WindowFrameAccess {
    var frame: CGRect?
    var isPositionSettable = true
    var isSizeSettable = true
    var minimumSize = CGSize.zero
    var positionError = AXError.success
    var sizeError = AXError.success

    init(frame: CGRect) { self.frame = frame }

    func setPosition(_ point: CGPoint) -> AXError {
        guard positionError == .success else { return positionError }
        frame?.origin = point
        return .success
    }

    func setSize(_ size: CGSize) -> AXError {
        guard sizeError == .success else { return sizeError }
        frame?.size = CGSize(width: max(size.width, minimumSize.width), height: max(size.height, minimumSize.height))
        return .success
    }
}
