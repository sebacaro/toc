import Cocoa

struct BottomThirdCalculation: WindowCalculation {
    func calculateRect(visibleFrame: CGRect, windowFrame: CGRect) -> CGRect {
        CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY + (visibleFrame.height / 3) * 2,
            width: visibleFrame.width,
            height: visibleFrame.height / 3
        )
    }
}
