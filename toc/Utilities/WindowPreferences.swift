import Foundation
import CoreGraphics

@MainActor
enum WindowPreferences {
    static var edgeThreshold: CGFloat {
        let stored = UserDefaults.standard.object(forKey: UserDefaultsKeys.snapEdgeThreshold) as? Double ?? 8
        return normalizedEdgeThreshold(CGFloat(stored))
    }

    static func isExcluded(bundleIdentifier: String?) -> Bool {
        isExcluded(
            bundleIdentifier: bundleIdentifier,
            in: UserDefaults.standard.string(forKey: UserDefaultsKeys.excludedApplications) ?? ""
        )
    }

    nonisolated static func normalizedEdgeThreshold(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 8 }
        return min(max(value, 1), 40)
    }

    nonisolated static func excludedBundleIdentifiers(from text: String) -> Set<String> {
        Set(text.components(separatedBy: .newlines).compactMap { line in
            let identifier = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return identifier.isEmpty ? nil : identifier
        })
    }

    nonisolated static func isExcluded(bundleIdentifier: String?, in text: String) -> Bool {
        guard let bundleIdentifier, !bundleIdentifier.isEmpty else { return false }
        return excludedBundleIdentifiers(from: text).contains(bundleIdentifier.lowercased())
    }
}
