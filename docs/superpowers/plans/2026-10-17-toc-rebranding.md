# toc Rebranding Implementation Plan

> **For agentic workers:** Execute this approved, mechanical rebranding in the current checkout and review the final diff. No runtime behavior changes.

**Goal:** Rename the personal macOS app, project, targets and shared scheme to `toc`.

**Architecture:** Keep the existing window-management code. Use `project.yml` as the source of truth and regenerate the Xcode project after renaming source paths.

**Tech Stack:** Swift 6, AppKit, SwiftUI, XcodeGen, KeyboardShortcuts.

**Spec:** User's Phase 2 requirements in this conversation and approval to proceed.

## Global Constraints

- App/product/project/shared scheme: `toc`; test target: `tocTests`.
- Bundle identifiers: `com.seba.toc` and `com.seba.toc.tests`.
- Keep macOS 14 minimum and existing dependency/version settings.
- Change only the project root; temporary tools may live in `/private/tmp`.
- Do not access or modify `noira`, its services, or any global configuration.
- Keep the original MIT license and upstream attribution; bundle the license as a resource.
- Keep the inherited AppIcon as a temporary icon and document its replacement.
- Compilation, runtime checks and DMG packaging belong to later phases.

## Review Focus

- Source/test paths and `@testable import` must match the renamed module.
- Debug and Release must use the new bundle IDs and executable paths.
- The checked-in shared scheme must reference both renamed targets.
- Visible app labels must say `toc`; upstream links must remain clearly attributed.
- The Xcode project must regenerate without installing a global tool.

## Task 1: Rename and regenerate

- [x] Rename source/test directories, app entry point and entitlements.
- [x] Update product/target settings and add an explicit shared `toc` scheme.
- [x] Update Info.plist, visible labels, logging fallback and test import.
- [x] Update README/CLAUDE commands and icon replacement instructions.
- [x] Regenerate the project using a temporary XcodeGen executable.
- [x] Validate plists, scheme XML, target references, bundle settings and diff; obtain independent review.

Verification uses static configuration checks for this reversible naming change. No new implementation tests, commits, app launches or changes to permissions are required in this phase.

## Verification record

- XcodeGen 2.46.0 downloaded to `/private/tmp`, SHA-256 verified against the official release asset, and project generated successfully. No global install.
- `plutil` validated the project, Info.plist and entitlements.
- Parsed generated project and shared scheme: app/test identifiers and paths verified in Debug and Release, scheme target IDs valid, archive uses Release.
- Original MIT license unchanged and present in the application resources phase.
- Independent review found no blocking omissions; 53 relocated files compared to upstream, with only the 7 intended identity changes.
- Compilation, app execution and DMG packaging remain for subsequent phases.
