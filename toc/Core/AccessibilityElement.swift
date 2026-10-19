import Cocoa
import ApplicationServices

@MainActor
final class AccessibilityElement: WindowFrameAccess {
    let element: AXUIElement

    init(_ element: AXUIElement) {
        self.element = element
        AXUIElementSetMessagingTimeout(element, 0.25)
    }

    static func frontmostApplication() -> AccessibilityElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AccessibilityElement(AXUIElementCreateApplication(app.processIdentifier))
    }

    static func focusedWindow() -> AccessibilityElement? {
        guard let app = frontmostApplication() else { return nil }
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app.element, kAXFocusedWindowAttribute as CFString, &ref) == .success,
              let ref, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        return AccessibilityElement(ref as! AXUIElement)
    }

    static func window(at point: CGPoint) -> AccessibilityElement? {
        guard point.x.isFinite, point.y.isFinite else { return nil }
        let system = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(system, 0.25)
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(system, Float(point.x), Float(point.y), &hit) == .success,
              let hit else { return nil }
        var current = AccessibilityElement(hit)
        for _ in 0..<8 {
            if current.attribute(kAXRoleAttribute) as? String == kAXWindowRole { return current }
            if let window = current.elementAttribute(kAXWindowAttribute) { return window }
            guard let parent = current.elementAttribute(kAXParentAttribute) else { return nil }
            current = parent
        }
        return nil
    }

    var position: CGPoint? {
        guard let value = attribute(kAXPositionAttribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        return AXValueGetValue(value as! AXValue, .cgPoint, &point) ? point : nil
    }

    var size: CGSize? {
        guard let value = attribute(kAXSizeAttribute), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        return AXValueGetValue(value as! AXValue, .cgSize, &size) ? size : nil
    }

    var frame: CGRect? {
        guard let position, let size else { return nil }
        return CGRect(origin: position, size: size)
    }

    var isPositionSettable: Bool { isSettable(kAXPositionAttribute) }
    var isSizeSettable: Bool { isSettable(kAXSizeAttribute) }

    func setPosition(_ point: CGPoint) -> AXError {
        var point = point
        guard let value = AXValueCreate(.cgPoint, &point) else { return .illegalArgument }
        return AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
    }

    func setSize(_ size: CGSize) -> AXError {
        var size = size
        guard let value = AXValueCreate(.cgSize, &size) else { return .illegalArgument }
        return AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value)
    }

    var bundleIdentifier: String? {
        guard let processIdentifier else { return nil }
        return NSRunningApplication(processIdentifier: processIdentifier)?.bundleIdentifier
    }

    func isSameWindow(as other: AccessibilityElement) -> Bool {
        CFEqual(element, other.element)
    }

    // Terminal's workaround must target this window's owner, even if focus changes.
    var isEnhancedUserInterfaceEnabled: Bool? {
        get { owningApplication?.attribute("AXEnhancedUserInterface") as? Bool }
        set {
            guard let app = owningApplication, let value = newValue else { return }
            AXUIElementSetAttributeValue(app.element, "AXEnhancedUserInterface" as CFString, value as CFTypeRef)
        }
    }

    private var processIdentifier: pid_t? {
        var pid: pid_t = 0
        return AXUIElementGetPid(element, &pid) == .success ? pid : nil
    }

    private var owningApplication: AccessibilityElement? {
        guard let processIdentifier else { return nil }
        return AccessibilityElement(AXUIElementCreateApplication(processIdentifier))
    }

    private func attribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }

    private func elementAttribute(_ name: String) -> AccessibilityElement? {
        guard let value = attribute(name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return AccessibilityElement(value as! AXUIElement)
    }

    private func isSettable(_ name: String) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, name as CFString, &settable) == .success && settable.boolValue
    }
}
