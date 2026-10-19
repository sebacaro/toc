# Reliable personal window management

The user approved a personal, reliable and complete window organizer for this Mac, following the Magnet gap analysis. No changes to noira, global Codex settings or system permissions. iCloud, green-button integration and a custom-command editor are outside this delivery.

## Required behavior

- Apply commands directly and in order; remove competing stepped window animations. Keep animated drag previews.
- Check AX write failures and supported attributes. Respect application minimum sizes, keep accepted geometry on the chosen screen where possible, and report actionable failures.
- Preserve the initial frame for restore; consume it only after a successful restore. Avoid the private window-ID API and cap retained history.
- Drag preview and release use the same captured window and exact destination rectangle/visible frame. Changing screens must update the preview even for the same action.
- Landscape: corners are quarters, sides are halves, top maximizes, bottom has five zones: left third, left two thirds, center third, right two thirds, right third.
- Portrait: corners remain quarters, side edges provide top third, top two thirds, middle third, bottom two thirds, bottom third; top maximizes and bottom provides left/right halves.
- Add explicit vertical third actions with editable shortcuts but no new default key conflicts.
- Recover snapping after Accessibility is granted, revoked or its event tap is disabled. Do not repeatedly prompt or change permissions automatically.
- Expose edge sensitivity (default 8 points, valid range 1...40) and app exclusions by bundle ID. Exclusions affect shortcuts and dragging.
- Unit-test geometry, negative screen coordinates, snap-zone mapping, constraints, errors, restore and preference parsing. Unit tests must not install event taps or request Accessibility.
- Build a universal Release app and replace the generated DMG only after successful validation.

## Implementation decisions

- Keep Swift/AppKit/SwiftUI and the existing KeyboardShortcuts dependency. Add no dependency.
- Serialize direct AX writes on the main actor, with bounded AX messaging timeout. An application can still refuse a requested size; report that constraint instead of claiming exact success.
- Use a small frame-access boundary to test application responses without moving real windows.
- Match AX elements using public CF equality for history instead of `_AXUIElementGetWindow`.
- Source of truth remains project.yml. XcodeGen stays under /private/tmp, with build products/caches in toc/build and packages in toc/dist.
- Original MIT license and provisional icon remain.

## Verification boundary

Automated tests exercise deterministic behavior and simulated AX responses. Real app compatibility, physical monitor arrangements, TCC transitions and perceived performance need manual validation with Accessibility granted. Do not represent those as automatically verified.
