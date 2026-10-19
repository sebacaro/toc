import CoreGraphics
import Testing
@testable import toc

@Suite("Window geometry")
struct WindowGeometryTests {
    @Test("Every layout uses the available screen rectangle with negative coordinates")
    func layoutRectangles() throws {
        let visibleFrame = CGRect(x: -1200, y: -700, width: 1200, height: 900)
        let expected: [(String, CGRect)] = [
            ("leftHalf", CGRect(x: -1200, y: -700, width: 600, height: 900)),
            ("rightHalf", CGRect(x: -600, y: -700, width: 600, height: 900)),
            ("topHalf", CGRect(x: -1200, y: -700, width: 1200, height: 450)),
            ("bottomHalf", CGRect(x: -1200, y: -250, width: 1200, height: 450)),
            ("topLeftQuarter", CGRect(x: -1200, y: -700, width: 600, height: 450)),
            ("topRightQuarter", CGRect(x: -600, y: -700, width: 600, height: 450)),
            ("bottomLeftQuarter", CGRect(x: -1200, y: -250, width: 600, height: 450)),
            ("bottomRightQuarter", CGRect(x: -600, y: -250, width: 600, height: 450)),
            ("leftThird", CGRect(x: -1200, y: -700, width: 400, height: 900)),
            ("centerThird", CGRect(x: -800, y: -700, width: 400, height: 900)),
            ("rightThird", CGRect(x: -400, y: -700, width: 400, height: 900)),
            ("leftTwoThirds", CGRect(x: -1200, y: -700, width: 800, height: 900)),
            ("rightTwoThirds", CGRect(x: -800, y: -700, width: 800, height: 900)),
            ("topThird", CGRect(x: -1200, y: -700, width: 1200, height: 300)),
            ("middleThird", CGRect(x: -1200, y: -400, width: 1200, height: 300)),
            ("bottomThird", CGRect(x: -1200, y: -100, width: 1200, height: 300)),
            ("topTwoThirds", CGRect(x: -1200, y: -700, width: 1200, height: 600)),
            ("bottomTwoThirds", CGRect(x: -1200, y: -400, width: 1200, height: 600)),
            ("maximize", visibleFrame),
        ]

        for (rawAction, expectedRect) in expected {
            let action = try #require(WindowAction(rawValue: rawAction), "Missing action: \(rawAction)")
            let calculation = try #require(WindowCalculationFactory.calculation(for: action))
            let actual = calculation.calculateRect(
                visibleFrame: visibleFrame,
                windowFrame: CGRect(x: 45, y: 67, width: 500, height: 400)
            )
            #expect(actual == expectedRect, "Incorrect rectangle for \(rawAction)")
        }
    }

    @Test("Center preserves the window size on an offset screen")
    func centerPreservesSize() throws {
        let calculation = try #require(WindowCalculationFactory.calculation(for: .center))
        let actual = calculation.calculateRect(
            visibleFrame: CGRect(x: -1200, y: -700, width: 1200, height: 900),
            windowFrame: CGRect(x: 400, y: 100, width: 500, height: 400)
        )
        #expect(actual == CGRect(x: -850, y: -450, width: 500, height: 400))
    }
}
