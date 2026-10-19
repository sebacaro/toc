import Cocoa

@MainActor
protocol WindowFrameAccess {
    var frame: CGRect? { get }
    var isPositionSettable: Bool { get }
    var isSizeSettable: Bool { get }
    func setPosition(_ point: CGPoint) -> AXError
    func setSize(_ size: CGSize) -> AXError
}

struct WindowMoveOutcome: Equatable {
    let actualFrame: CGRect
    let wasConstrained: Bool
}

enum WindowMoveFailure: Error, Equatable {
    case invalidFrame
    case unavailable
    case notMovable
    case notResizable
    case accessibility(AXError)
}

@MainActor
enum WindowFrameWriter {
    static func apply(_ requested: CGRect, to window: any WindowFrameAccess,
                      visibleFrame: CGRect) -> Result<WindowMoveOutcome, WindowMoveFailure> {
        guard isValid(requested), isValid(visibleFrame) else { return .failure(.invalidFrame) }
        guard let original = window.frame, isValid(original) else { return .failure(.unavailable) }

        var target = requested
        target.size.width = min(target.width, visibleFrame.width)
        target.size.height = min(target.height, visibleFrame.height)
        target.origin = fittedOrigin(for: target, in: visibleFrame)
        let canResize = window.isSizeSettable
        let canMove = window.isPositionSettable
        guard canResize || original.size == target.size else { return .failure(.notResizable) }
        guard canMove || original.origin == target.origin else { return .failure(.notMovable) }

        // Size-position-size lets macOS re-evaluate limits after crossing displays.
        if canResize {
            let error = window.setSize(target.size)
            guard error == .success else { return .failure(.accessibility(error)) }
        }
        if canMove {
            let error = window.setPosition(target.origin)
            guard error == .success else { return .failure(.accessibility(error)) }
        }
        if canResize {
            let error = window.setSize(target.size)
            guard error == .success else { return .failure(.accessibility(error)) }
        }
        guard var actual = window.frame, isValid(actual) else { return .failure(.unavailable) }
        let fitted = fittedOrigin(for: actual, in: visibleFrame)
        if fitted != actual.origin, canMove {
            let error = window.setPosition(fitted)
            guard error == .success else { return .failure(.accessibility(error)) }
            guard let corrected = window.frame, isValid(corrected) else { return .failure(.unavailable) }
            actual = corrected
        }
        return .success(WindowMoveOutcome(actualFrame: actual, wasConstrained: !approximatelyEqual(actual, requested)))
    }

    private static func isValid(_ rect: CGRect) -> Bool {
        [rect.origin.x, rect.origin.y, rect.width, rect.height].allSatisfy(\.isFinite)
            && rect.width > 0 && rect.height > 0
    }

    private static func fittedOrigin(for rect: CGRect, in bounds: CGRect) -> CGPoint {
        CGPoint(x: max(bounds.minX, min(rect.minX, bounds.maxX - rect.width)),
                y: max(bounds.minY, min(rect.minY, bounds.maxY - rect.height)))
    }

    private static func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) <= 1 && abs(lhs.minY - rhs.minY) <= 1
            && abs(lhs.width - rhs.width) <= 1 && abs(lhs.height - rhs.height) <= 1
    }
}
