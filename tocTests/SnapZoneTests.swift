import CoreGraphics
import Testing
@testable import toc

@Suite("Snap zones")
struct SnapZoneTests {
    private let frame = CGRect(x: -1200, y: -800, width: 1200, height: 800)
    private let visibleFrame = CGRect(x: -1200, y: -775, width: 1200, height: 735)

    @Test("Landscape edges and corners select the expected layouts")
    func landscapeEdges() throws {
        let expected: [(CGPoint, String)] = [
            (CGPoint(x: -1200, y: -400), "leftHalf"),
            (CGPoint(x: 0, y: -400), "rightHalf"),
            (CGPoint(x: -600, y: -800), "maximize"),
            (CGPoint(x: -1200, y: -750), "topLeftQuarter"),
            (CGPoint(x: 0, y: -750), "topRightQuarter"),
            (CGPoint(x: -1200, y: -50), "bottomLeftQuarter"),
            (CGPoint(x: 0, y: -50), "bottomRightQuarter"),
            (CGPoint(x: -1150, y: -800), "topLeftQuarter"),
            (CGPoint(x: -50, y: 0), "bottomRightQuarter"),
        ]
        for (point, rawAction) in expected {
            let zone = try #require(SnapZoneDetector.detect(
                mouseLocation: point, frame: frame, visibleFrame: visibleFrame
            ))
            #expect(zone.action.rawValue == rawAction)
            #expect(zone.visibleFrame == visibleFrame)
        }
    }

    @Test("The five bottom zones include thirds and two thirds")
    func landscapeThirds() throws {
        let expected: [(CGFloat, String, CGRect)] = [
            (-1080, "leftThird", CGRect(x: -1200, y: -775, width: 400, height: 735)),
            (-840, "leftTwoThirds", CGRect(x: -1200, y: -775, width: 800, height: 735)),
            (-600, "centerThird", CGRect(x: -800, y: -775, width: 400, height: 735)),
            (-360, "rightTwoThirds", CGRect(x: -800, y: -775, width: 800, height: 735)),
            (-120, "rightThird", CGRect(x: -400, y: -775, width: 400, height: 735)),
        ]
        for (x, rawAction, expectedRect) in expected {
            let zone = try #require(SnapZoneDetector.detect(
                mouseLocation: CGPoint(x: x, y: 0), frame: frame, visibleFrame: visibleFrame
            ))
            #expect(zone.action.rawValue == rawAction)
            #expect(zone.rect == expectedRect)
        }
    }

    @Test("Portrait side zones divide the available height")
    func portraitThirds() throws {
        let portraitFrame = CGRect(x: 1200, y: -300, width: 900, height: 1600)
        let portraitVisibleFrame = CGRect(x: 1200, y: -276, width: 900, height: 1536)
        let expected: [(CGFloat, String, CGRect)] = [
            (-140, "topThird", CGRect(x: 1200, y: -276, width: 900, height: 512)),
            (180, "topTwoThirds", CGRect(x: 1200, y: -276, width: 900, height: 1024)),
            (500, "middleThird", CGRect(x: 1200, y: 236, width: 900, height: 512)),
            (820, "bottomTwoThirds", CGRect(x: 1200, y: 236, width: 900, height: 1024)),
            (1140, "bottomThird", CGRect(x: 1200, y: 748, width: 900, height: 512)),
        ]
        for x in [CGFloat(1200), CGFloat(2100)] {
            for (y, rawAction, expectedRect) in expected {
                let zone = try #require(SnapZoneDetector.detect(
                    mouseLocation: CGPoint(x: x, y: y),
                    frame: portraitFrame, visibleFrame: portraitVisibleFrame
                ))
                #expect(zone.action.rawValue == rawAction)
                #expect(zone.rect == expectedRect)
            }
        }
    }

    @Test("Portrait top and bottom edges retain maximize and horizontal halves")
    func portraitTopAndBottom() throws {
        let portraitFrame = CGRect(x: 1200, y: -300, width: 900, height: 1600)
        let expected: [(CGPoint, String)] = [
            (CGPoint(x: 1650, y: -300), "maximize"),
            (CGPoint(x: 1425, y: 1300), "leftHalf"),
            (CGPoint(x: 1875, y: 1300), "rightHalf"),
            (CGPoint(x: 1200, y: -250), "topLeftQuarter"),
            (CGPoint(x: 2100, y: 1250), "bottomRightQuarter"),
        ]
        for (point, rawAction) in expected {
            let zone = try #require(SnapZoneDetector.detect(
                mouseLocation: point, frame: portraitFrame, visibleFrame: portraitFrame
            ))
            #expect(zone.action.rawValue == rawAction)
        }
    }

    @Test("Cursor positions away from any edge do not snap")
    func rejectsInteriorAndDistantPositions() {
        for point in [
            CGPoint(x: -600, y: -400),
            CGPoint(x: -1241, y: -400),
            CGPoint(x: 41, y: -400),
            CGPoint(x: -600, y: -841),
            CGPoint(x: -600, y: 41),
        ] {
            #expect(SnapZoneDetector.detect(
                mouseLocation: point, frame: frame, visibleFrame: visibleFrame,
                edgeThreshold: 1000
            ) == nil)
        }
    }

    @Test("Sensitivity clamps to a usable range")
    func sensitivityClamping() throws {
        let minimum = try #require(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: -1199, y: -400), frame: frame, visibleFrame: visibleFrame,
            edgeThreshold: -10
        ))
        #expect(minimum.action == .leftHalf)
        #expect(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: -1198, y: -400), frame: frame, visibleFrame: visibleFrame,
            edgeThreshold: -10
        ) == nil)

        let maximum = try #require(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: -1160, y: -400), frame: frame, visibleFrame: visibleFrame,
            edgeThreshold: 1000
        ))
        #expect(maximum.action == .leftHalf)
        #expect(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: -1159, y: -400), frame: frame, visibleFrame: visibleFrame,
            edgeThreshold: 1000
        ) == nil)
    }

    @Test("Large corner settings leave usable zones on small displays")
    func smallDisplayCorners() throws {
        let smallFrame = CGRect(x: 0, y: 0, width: 200, height: 100)
        let side = try #require(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: 0, y: 50), frame: smallFrame, visibleFrame: smallFrame,
            cornerSize: 1000
        ))
        #expect(side.action == .leftHalf)
        let bottom = try #require(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: 30, y: 100), frame: smallFrame, visibleFrame: smallFrame,
            cornerSize: 1000
        ))
        #expect(bottom.action.rawValue == "leftThird")
    }

    @Test("Invalid coordinates and empty screens do not create zones")
    func invalidGeometry() {
        #expect(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: CGFloat.nan, y: 0), frame: frame, visibleFrame: visibleFrame
        ) == nil)
        #expect(SnapZoneDetector.detect(
            mouseLocation: .zero, frame: .zero, visibleFrame: .zero
        ) == nil)
        #expect(SnapZoneDetector.detect(
            mouseLocation: CGPoint(x: -1200, y: -400), frame: frame, visibleFrame: .zero
        ) == nil)
    }
}
