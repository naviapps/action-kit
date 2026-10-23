# Changelog

All notable user-facing changes to ActionKit will be documented in this file.

Released versions follow semantic versioning.

## [Unreleased]

### Added

- Added `ShortcutsCatalog` to ActionKitAppKit for bounded, cancellable system
  shortcut-name listing without executing shortcuts or retaining raw stderr.
- Added typed catalog failures and case-preserving name decoding, with injected
  executable fixtures covering process I/O, limits, deadlines and cancellation.

## [2.0.0] - 2026-07-12

### Changed

- Raised the package requirements to macOS 14 and Swift 6.0.
- Added stricter decoding validation for action input descriptors, permission sets, action
  attempts, and AppleScript error metadata.
- Tightened action, action-input, and action-envelope decoding so unknown top-level fields are
  rejected instead of silently ignored.
- Tightened result, permission-set, and input-metadata decoding so unknown top-level fields are
  rejected instead of silently ignored.
- Replaced the duplicate `ActionKind.action()` and `ActionKind.action(input:)` API with the
  clearer `ActionKind.makeAction()` and `ActionKind.makeAction(input:)` names.
- Kept static action metadata construction internal and non-trapping while preserving public
  descriptor validation.
- Removed the duplicate `ActionKind.inputShape` convenience; hosts should use
  `ActionKind.inputDescriptor.shape` so input shape and parameter metadata have one source of truth.
- Made ActionKit-owned focused-window placement, screen, area, and direction values directly
  `Codable`, with `WindowPlacementRequest` and `WindowMoveRequest` using those public payload
  contracts instead of private duplicate wrappers.
- Removed duplicate fixed half, third, and quarter placement cases from the public focused-window
  placement value; hosts should use explicit `ActionWindowPlacement.grid` payloads for those
  layouts so there is one canonical placement contract.
- Removed duplicate input-free focused-window placement and screen-move action catalog cases;
  hosts should create `Action.windowPlacement` and `Action.windowMove` values with explicit
  request payloads so the action catalog has one canonical windowing contract.
- Tightened focused-window placement and screen payload decoding so associated fields are only
  accepted for the matching payload kind.
- Tightened `ActionOutcome` so public result observations always contain at least one recorded
  attempt; empty internal plans are reported as internal-error attempts.
- Documented and guarded the factory-only `ActionError` construction boundary so raw error payload
  fabrication stays out of the public API.
- Removed `@testable` imports from package tests and kept executor dependency injection, live
  adapter test seams, and WindowKit mapping checks behind Swift `package` access instead of
  widening them into public API.
- Added `WINDOW_KIT_PATH` support for testing against a local WindowKit checkout.
- Tightened input descriptor validation and public API documentation.
- Raised the required WindowKit dependency to 2.0.0 for its breaking windowing contract update.
- Updated installation guidance to use the 2.0.0 release line.
- Added README links to release notes.
- Clarified that security updates target the latest released version.

## [1.0.0] - 2026-05-26

### Added

- Initial public release.
- `ActionKit` model layer for common macOS actions, canonical action identifiers, input
  descriptors, execution capabilities, permission preflight data, permission hints, versioned
  `Codable` envelopes, and observable result types.
- `ActionKitAppKit` live executor for running actions through AppKit, Core Graphics events,
  AppleScript, Shortcuts URLs, screen capture, and WindowKitAppKit focused-window control.

## [0.1.0] - 2026-05-26

### Added

- Initial public release.
