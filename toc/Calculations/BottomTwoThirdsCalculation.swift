import Cocoa

struct BottomTwoThirdsCalculation: WindowCalculation {
    func calculateRect(visibleFrame: CGRect, windowFrame: CGRect) -> CGRect {
        CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY + visibleFrame.height / 3,
            width: visibleFrame.width,
            height: (visibleFrame.height / 3) * 2
        )
    }
}
