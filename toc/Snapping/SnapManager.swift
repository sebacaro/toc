import Cocoa

@MainActor
final class SnapManager {
    static let shared = SnapManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var recoveryTimer: Timer?
    private let overlayWindow = SnapOverlayWindow()
    private var isRunning = false
    private var isDragging = false
    private var dragWindow: AccessibilityElement?
    private var dragStartFrame: CGRect?
    private var currentSnapZone: SnapZone?

    private init() {}

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: UserDefaultsKeys.snappingEnabled) as? Bool ?? true
    }

    func start() {
        guard !isRunning, isEnabled else { return }
        isRunning = true
        refreshPermissionAndTap()

        // Poll only while snapping is enabled, without repeatedly prompting for TCC access.
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshPermissionAndTap() }
        }
        RunLoop.main.add(timer, forMode: .common)
        recoveryTimer = timer
    }

    func stop() {
        isRunning = false
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        removeEventTap()
        resetDrag()
    }

    private func refreshPermissionAndTap() {
        guard isRunning else { return }
        guard isEnabled else {
            stop()
            return
        }
        guard AccessibilityPermission.isTrusted else {
            removeEventTap()
            resetDrag()
            return
        }
        if let tap = eventTap {
            if CFMachPortIsValid(tap) {
                if !CGEvent.tapIsEnabled(tap: tap) {
                    resetDrag()
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return
            }
            removeEventTap()
        }
        createEventTap()
    }

    private func createEventTap() {
        let mask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<SnapManager>.fromOpaque(userInfo).takeUnretainedValue()
                let location = event.location
                DispatchQueue.main.async {
                    manager.handleEvent(type: type, location: location)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeEventTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CFMachPortInvalidate(tap)
        eventTap = nil
        runLoopSource = nil
    }

    private func handleEvent(type: CGEventType, location: CGPoint) {
        guard isRunning, isEnabled else { return }
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            resetDrag()
            refreshPermissionAndTap()
        case .leftMouseDown:
            handleMouseDown(location: location)
        case .leftMouseDragged:
            handleMouseDragged(location: location)
        case .leftMouseUp:
            handleMouseUp(location: location)
        default:
            break
        }
    }

    private func handleMouseDown(location: CGPoint) {
        resetDrag()
        guard AccessibilityPermission.isTrusted,
              let window = AccessibilityElement.window(at: location),
              !WindowPreferences.isExcluded(bundleIdentifier: window.bundleIdentifier),
              let frame = window.frame else { return }
        dragWindow = window
        dragStartFrame = frame
    }

    private func handleMouseDragged(location: CGPoint) {
        guard let window = dragWindow, let start = dragStartFrame else { return }
        guard let focused = AccessibilityElement.focusedWindow(),
              window.isSameWindow(as: focused),
              !WindowPreferences.isExcluded(bundleIdentifier: window.bundleIdentifier),
              let frame = window.frame else {
            resetDrag()
            return
        }

        let sizeChanged = abs(frame.width - start.width) > 5 || abs(frame.height - start.height) > 5
        if sizeChanged {
            resetDrag()
            return
        }
        if abs(frame.minX - start.minX) > 5 || abs(frame.minY - start.minY) > 5 {
            isDragging = true
        }
        guard isDragging else { return }

        let zone = SnapZoneDetector.detect(mouseLocation: location, edgeThreshold: WindowPreferences.edgeThreshold)
        guard currentSnapZone != zone else { return }
        currentSnapZone = zone
        if let zone {
            overlayWindow.show(at: zone.rect)
        } else {
            overlayWindow.hide()
        }
    }

    private func handleMouseUp(location: CGPoint) {
        defer { resetDrag() }
        guard isDragging, let window = dragWindow,
              let focused = AccessibilityElement.focusedWindow(),
              window.isSameWindow(as: focused),
              !WindowPreferences.isExcluded(bundleIdentifier: window.bundleIdentifier),
              let zone = currentSnapZone,
              zone == SnapZoneDetector.detect(mouseLocation: location, edgeThreshold: WindowPreferences.edgeThreshold) else { return }
        WindowManager.shared.executeSnap(zone, window: window)
    }

    private func resetDrag() {
        isDragging = false
        dragWindow = nil
        dragStartFrame = nil
        currentSnapZone = nil
        overlayWindow.hide()
    }
}
