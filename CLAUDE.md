# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Regenerate Xcode project after adding/removing files (uses XcodeGen)
xcodegen

# Build
xcodebuild -project toc.xcodeproj -scheme toc -configuration Debug -derivedDataPath build -destination 'platform=macOS' build

# Run the built app
open build/Build/Products/Debug/toc.app

# Test (AX responses are simulated, no real windows are moved)
xcodebuild -project toc.xcodeproj -scheme toc -configuration Debug -derivedDataPath build -destination 'platform=macOS' -parallel-testing-enabled NO -only-testing:tocTests test

# Package a DMG (needs a Release build in build/)
bash scripts/package-dmg.sh
```

**You must run `xcodegen` after creating or deleting any Swift file** — the project.yml sources the entire `toc/` directory, but the .xcodeproj needs regeneration to pick up changes.

## Project identity

App, target and shared scheme: `toc`. Tests: `tocTests`. Bundle IDs: `com.seba.toc` and `com.seba.toc.tests`.

This personal project is based on [Magnetism](https://github.com/sadopc/magnetism). Preserve the original MIT license. The approved purple T icon comes from docs/branding/toc-icon-purple-t-v2.png; its macOS sizes are in toc/Assets.xcassets/AppIcon.appiconset/.

## Architecture

Menu-bar-only macOS window manager (LSUIElement=true, no dock icon). Swift 6 strict concurrency, macOS 14+, single SPM dependency: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).

### Data Flow

```
ShortcutManager (onKeyUp)   ──┐
MenuBarManager (NSMenuItem) ──┴──→ WindowManager.execute(WindowAction)
                                        │
                      ┌─────────────────┼──────────────────┐
                      ↓                 ↓                  ↓
                  .restore       .nextDisplay /       layout actions
                      │          .previousDisplay           │
               WindowHistory      ScreenManager     WindowCalculationFactory
                      └─────────────────┼──────────────────┘
                                        ↓
SnapManager (CGEvent tap) ──→ WindowManager.executeSnap(SnapZone, window)
                                        │
                                        ↓
                         WindowManager.move → WindowFrameWriter.apply
                         (AX API via AccessibilityElement: size → position → size)
```

### Key Modules

- **Core/** — `WindowManager` orchestrates everything. `AccessibilityElement` wraps AXUIElement. `WindowFrameWriter` applies a target frame through the `WindowFrameAccess` protocol (so tests can simulate AX) and returns a `Result` with the actual frame or a typed failure. `WindowHistory` keeps up to 128 pre-move frames, in memory only. `WindowAction` enum is the single source of truth for all 23 actions (display names, categories, shortcut bindings via extension in ShortcutNames.swift).
- **Calculations/** — One struct per layout action, all conforming to `WindowCalculation` protocol. Factory in `WindowCalculation.swift` maps `WindowAction` → calculation. `.restore`, `.nextDisplay` and `.previousDisplay` have no calculation; `WindowManager` handles them directly.
- **Shortcuts/** — `ShortcutNames.swift` defines `KeyboardShortcuts.Name` constants with Magnet-compatible defaults. The five vertical thirds/two-thirds actions have no default binding. `ShortcutManager` registers `onKeyUp` handlers.
- **Snapping/** — `SnapManager` uses a passive CGEvent tap (`.listenOnly`) and a 1 s timer that recreates the tap after a permission grant or a timeout. `SnapZone.swift` holds `SnapZone` and `SnapZoneDetector`, which checks the mouse position against screen edges/corners using `WindowPreferences.edgeThreshold`. `SnapOverlayWindow` shows a fading preview.
- **Preferences/** — `PreferencesWindowController` hosts SwiftUI views in an AppKit NSWindow (SwiftUI Settings scene is unreliable in LSUIElement apps). `Utilities/WindowPreferences.swift` stores the snap sensitivity and the excluded bundle IDs.

## Critical Technical Patterns

### Coordinate Flipping
NSScreen uses bottom-left origin; AX API uses top-left origin. **All** window calculations must use `NSScreen.flippedVisibleFrame` (defined in `CGExtensions.swift`), never raw `visibleFrame`. The overlay window converts back with `CGRect.screenFlipped()` for display.

### Triple-Set Pattern
`WindowFrameWriter.apply` does `setSize → setPosition → setSize`. macOS enforces per-display size limits during cross-display moves — setting size twice ensures the final frame is exact. It then reads the frame back, pulls the window inside the visible frame if needed, and reports `wasConstrained` when the app refused the requested geometry.

### Direct Movement
Windows move in one synchronous step on the main actor; there is no window animation. Only the snap overlay animates.

### CGEvent Tap Memory Management
`SnapManager` passes `self` to the C callback via `Unmanaged.passUnretained()`. The `eventTap` property **must** be held — if it's deallocated, the tap stops working silently. The callback only copies the event location and dispatches the handling to the main queue.

### AXEnhancedUserInterface Workaround
`WindowManager.move()` temporarily disables `AXEnhancedUserInterface` on the window's owning app (needed for Terminal.app, applied to any app that has it enabled), then re-enables it in a `defer` block.

### No Private API
`WindowHistory` identifies windows with `CFEqual` on the `AXUIElement` (`AccessibilityElement.isSameWindow(as:)`), not with `CGWindowID`. Do not reintroduce `_AXUIElementGetWindow`.

## Swift 6 Concurrency Strategy

All singleton managers are `@MainActor final class`. No async/await patterns. Nothing runs off the main thread except the CGEvent tap callback, which immediately hops to the main queue.

The `kAXTrustedCheckOptionPrompt` global variable triggers a Swift 6 concurrency warning — worked around by using the string literal `"AXTrustedCheckOptionPrompt"` directly in `AccessibilityPermission.swift`.

## Adding a New Window Layout

1. Add a case to `WindowAction` enum (with `displayName` and `category`)
2. Create `Calculations/[Name]Calculation.swift` conforming to `WindowCalculation`
3. Add the case to `WindowCalculationFactory.calculation(for:)`
4. Add a `KeyboardShortcuts.Name` in `ShortcutNames.swift` (a default binding is optional)
5. Add the mapping in the `WindowAction.shortcutName` extension
6. Run `xcodegen` to pick up the new file

## Permissions

- **No App Sandbox** — required for AX API access
- **Accessibility permission** — prompted on first launch; re-prompted during development because ad-hoc re-signing invalidates the trust entry
- **No Input Monitoring needed** — CGEvent tap uses `.listenOnly` mode
