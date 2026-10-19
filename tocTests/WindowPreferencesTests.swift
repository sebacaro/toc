import CoreGraphics
import Testing
@testable import toc

@Suite("Window preferences")
struct WindowPreferencesTests {
    @Test("Snap sensitivity stays within usable bounds")
    func sensitivityIsClamped() {
        #expect(WindowPreferences.normalizedEdgeThreshold(-5) == 1)
        #expect(WindowPreferences.normalizedEdgeThreshold(0) == 1)
        #expect(WindowPreferences.normalizedEdgeThreshold(18) == 18)
        #expect(WindowPreferences.normalizedEdgeThreshold(100) == 40)
    }

    @Test("Corrupt sensitivity falls back to a usable default")
    func nonFiniteSensitivityUsesDefault() {
        #expect(WindowPreferences.normalizedEdgeThreshold(.nan) == 8)
        #expect(WindowPreferences.normalizedEdgeThreshold(.infinity) == 8)
        #expect(WindowPreferences.normalizedEdgeThreshold(-.infinity) == 8)
    }

    @Test("Exclusion input trims lines, ignores blanks and removes duplicates")
    func exclusionInputIsNormalized() {
        let input = "  com.apple.Safari  \n\ncom.apple.finder\r\nCOM.APPLE.SAFARI\n  "
        #expect(WindowPreferences.excludedBundleIdentifiers(from: input) == ["com.apple.safari", "com.apple.finder"])
    }

    @Test("Exclusions match only the complete bundle identifier")
    func exclusionsDoNotMatchOtherApps() {
        let input = "com.apple.Safari\ncom.example.Editor"
        #expect(WindowPreferences.isExcluded(bundleIdentifier: "com.apple.SAFARI", in: input))
        #expect(!WindowPreferences.isExcluded(bundleIdentifier: "com.apple.SafariTechnologyPreview", in: input))
        #expect(!WindowPreferences.isExcluded(bundleIdentifier: "com.apple", in: input))
        #expect(!WindowPreferences.isExcluded(bundleIdentifier: nil, in: input))
        #expect(!WindowPreferences.isExcluded(bundleIdentifier: "", in: input))
        #expect(!WindowPreferences.isExcluded(bundleIdentifier: "com.apple.Safari", in: "\n  "))
    }
}
