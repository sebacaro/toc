# Personal Window Management Implementation Plan

> **For agentic workers:** Implement independent geometry and lifecycle tasks in parallel with the core movement task; root owns integrated tests, Release, review and DMG.

**Goal:** Deliver the approved reliable personal window organizer and updated installer.

**Architecture:** Keep native managers and add deterministic snap-zone/geometry entry points and a small AX frame-writer boundary. Apply direct movements on the main actor, preserve the dragged destination and window, and monitor permission recovery while snapping is enabled.

**Tech Stack:** Swift 6, AppKit, SwiftUI, Swift Testing, XcodeGen, hdiutil.

**Spec:** `docs/superpowers/specs/2026-10-17-personal-window-management.md`

## Global Constraints

- Changes only in toc; temporary tools only in /private/tmp. No noira or global settings.
- macOS 14+, bundle com.seba.toc, existing dependency only.
- Keep original MIT license. No automatic permission changes or real-window manipulation during tests.
- Existing work is uncommitted; preserve it. Baseline snapshot: build/baseline-personal.

## Review Focus

- Consecutive commands and minimum-size/AX failures leave honest results.
- Preview and release remain coherent across monitors, including negative origins and portrait screens.
- Permission recovery never stacks event taps/timers or repeatedly prompts.
- Exclusions are exact bundle-ID matches and all layout commands stay available.
- Release and installed DMG retain correct identity, signing and license.

## Tasks

- [x] Write regression tests first and capture RED evidence.
- [x] Implement checked direct movement, public history identity and restore safety.
- [x] Implement landscape/portrait snap zones and vertical third actions.
- [x] Implement permission/tap recovery, stable overlay and preferences/exclusions.
- [x] Regenerate project and run the complete test suite; fix integration failures.
- [x] Obtain independent review, build Release and validate app metadata/signature.
- [x] Rebuild and mount-verify DMG; update installation and behavior documentation.

## Verification evidence

- Tests were written first. Initial RED: `build/logs/personal-red.log` (missing AppRuntime); history regression RED: `build/logs/history-red.log` (missing recordChange). These were compiler failures from absent APIs, not executed assertion failures.
- Integrated GREEN: 34 tests / 7 suites, `build/logs/personal-tests.log`, 2026-10-18.
- Independent code review found one P2: rejected commands could leave stale restore history. Fixed and re-reviewed: save only observed changes, including partial AX failures. No remaining P1/P2 identified by review.
- Drag starts with an AX hit test instead of the previously focused window. Release validates the last previewed destination before applying it.
- No source, service, permission or settings changes outside toc; temporary XcodeGen remains under /private/tmp.
- Manual coverage remains pending for actual input, TCC transitions, Spaces, physical monitor layouts and performance.

- Final Release: toc 1.1.0 (3), arm64+x86_64, valid ad hoc signature, zero Swift compiler warnings. `build/logs/personal-release-verification.json`.
- Final DMG: hdiutil verify and SHA-256 passed; mounted read-only, checked identity/license/docs/Applications link and exact executable match, then detached. `build/logs/dmg-verification.json`.
