import Cocoa

struct SnapZone: Equatable {
    let action: WindowAction
    let rect: CGRect
    let visibleFrame: CGRect
}

enum SnapZoneDetector {
    /// Mouse, screen and preview rectangles all use AX/top-left coordinates.
    static func detect(
        mouseLocation: CGPoint,
        edgeThreshold: CGFloat = 8,
        cornerSize: CGFloat = 100
    ) -> SnapZone? {
        // A screen containing the pointer wins over a neighboring screen's edge margin.
        let screens = NSScreen.screens
        if let screen = screens.first(where: { $0.flippedFrame.contains(mouseLocation) }) {
            return detect(
                mouseLocation: mouseLocation,
                frame: screen.flippedFrame,
                visibleFrame: screen.flippedVisibleFrame,
                edgeThreshold: edgeThreshold,
                cornerSize: cornerSize
            )
        }
        for screen in screens {
            if let zone = detect(
                mouseLocation: mouseLocation,
                frame: screen.flippedFrame,
                visibleFrame: screen.flippedVisibleFrame,
                edgeThreshold: edgeThreshold,
                cornerSize: cornerSize
            ) {
                return zone
            }
        }
        return nil
    }

    static func detect(
        mouseLocation: CGPoint,
        frame: CGRect,
        visibleFrame: CGRect,
        edgeThreshold: CGFloat = 8,
        cornerSize: CGFloat = 100
    ) -> SnapZone? {
        guard mouseLocation.x.isFinite, mouseLocation.y.isFinite,
              !frame.isEmpty, !frame.isInfinite, !frame.isNull,
              !visibleFrame.isEmpty, !visibleFrame.isInfinite, !visibleFrame.isNull else {
            return nil
        }

        let threshold = edgeThreshold.isFinite ? min(max(edgeThreshold, 1), 40) : 8
        guard mouseLocation.x >= frame.minX - threshold,
              mouseLocation.x <= frame.maxX + threshold,
              mouseLocation.y >= frame.minY - threshold,
              mouseLocation.y <= frame.maxY + threshold else {
            return nil
        }

        // Keep both extreme fifths reachable even with small screens or large corner settings.
        let requestedCorner = cornerSize.isFinite ? max(0, cornerSize) : 100
        let corner = min(requestedCorner, min(frame.width, frame.height) / 5)
        let atLeft = mouseLocation.x <= frame.minX + threshold
        let atRight = mouseLocation.x >= frame.maxX - threshold
        let atTop = mouseLocation.y <= frame.minY + threshold
        let atBottom = mouseLocation.y >= frame.maxY - threshold
        let nearLeft = mouseLocation.x <= frame.minX + corner
        let nearRight = mouseLocation.x >= frame.maxX - corner
        let nearTop = mouseLocation.y <= frame.minY + corner
        let nearBottom = mouseLocation.y >= frame.maxY - corner

        let action: WindowAction
        if (atLeft && nearTop) || (atTop && nearLeft) {
            action = .topLeftQuarter
        } else if (atRight && nearTop) || (atTop && nearRight) {
            action = .topRightQuarter
        } else if (atLeft && nearBottom) || (atBottom && nearLeft) {
            action = .bottomLeftQuarter
        } else if (atRight && nearBottom) || (atBottom && nearRight) {
            action = .bottomRightQuarter
        } else if atTop {
            action = .maximize
        } else if frame.height > frame.width {
            if atLeft || atRight {
                let actions: [WindowAction] = [.topThird, .topTwoThirds, .middleThird, .bottomTwoThirds, .bottomThird]
                let index = min(max(Int((mouseLocation.y - frame.minY) / frame.height * 5), 0), 4)
                action = actions[index]
            } else if atBottom {
                action = mouseLocation.x < frame.midX ? .leftHalf : .rightHalf
            } else {
                return nil
            }
        } else if atLeft {
            action = .leftHalf
        } else if atRight {
            action = .rightHalf
        } else if atBottom {
            let actions: [WindowAction] = [.leftThird, .leftTwoThirds, .centerThird, .rightTwoThirds, .rightThird]
            let index = min(max(Int((mouseLocation.x - frame.minX) / frame.width * 5), 0), 4)
            action = actions[index]
        } else {
            return nil
        }

        guard let calculation = WindowCalculationFactory.calculation(for: action) else { return nil }
        return SnapZone(
            action: action,
            rect: calculation.calculateRect(visibleFrame: visibleFrame, windowFrame: visibleFrame),
            visibleFrame: visibleFrame
        )
    }
}
