# ActionKit

[![CI](https://github.com/naviapps/action-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/action-kit/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Swift versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Faction-kit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/naviapps/action-kit)
[![Supported platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnaviapps%2Faction-kit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/naviapps/action-kit)

ActionKit is a Swift package for describing, preflighting, and executing common macOS actions.
It provides reusable action models for editing, media keys, workspace launching, shortcuts,
screen capture, system controls, focused-window placement, and focused-window screen movement.

The package is split into two libraries:

- `ActionKit`: action models, versioned JSON envelopes, permission requirements, permission hints,
  result types, and focused-window placement and movement requests.
- `ActionKitAppKit`: live macOS execution backed by AppKit, Core Graphics events, AppleScript,
  Shortcuts URLs, screen capture, and WindowKitAppKit window control.

## Architecture

```text
Host app
  -> ActionKit
     - action models
     - canonical action identifiers
     - input descriptors
     - permission preflight
     - versioned JSON envelopes
  -> ActionKitAppKit
     - AppKit, Core Graphics, AppleScript, Shortcuts, screencapture, WindowKitAppKit
```

ActionKit is built for launcher apps, automation tools, keyboard-driven utilities, local
assistants, and workflow systems that need a typed boundary between "what should happen" and the
macOS APIs that perform it.

Typical integrations include:

- launcher apps that expose a curated action catalog with dynamic input forms
- keyboard utilities that preflight permissions before dispatching focused-app or focused-window
  actions
- local assistants that serialize suggested actions, inspect capabilities, and ask the host app to
  execute them

Typical lifecycle:

```text
ActionKind catalog
  -> inputDescriptor and capabilities
  -> ActionPreflight permission hints
  -> ActionCodec JSON envelope
  -> ActionExecutor live execution
  -> ActionOutcome observation
```

Action identifiers are the canonical serialization names for the current action catalog. Use
`ActionKind.identifier` and `ActionCodec` payloads for persistence, IPC, and tool bindings instead
of relying on enum case names as external protocol strings.

## Responsibility Boundary

ActionKit describes and preflights actions, while ActionKitAppKit provides the default live
executor. Host apps are responsible for:

- permission onboarding and user-facing prompts
- shortcut registration, gesture recognition, menus, and UI
- persistence, analytics, telemetry, and privacy policy choices
- deciding which actions are exposed to users
- handling app-specific recovery when macOS denies access

The package does not request permissions, collect analytics, transmit data, or persist action
history by itself.

## Requirements

- macOS 14 or later
- Swift 6.0 or later
- WindowKit 2.0.0 or later for the `ActionKitAppKit` live execution product

## Installation

Add this package to your Swift Package dependencies:

```swift
.package(url: "https://github.com/naviapps/action-kit.git", from: "2.0.0")
```

Then add the product that matches your use case:

```swift
.product(name: "ActionKit", package: "action-kit"),
.product(name: "ActionKitAppKit", package: "action-kit"),
```

Use `ActionKit` when you only need models, versioned JSON action envelopes, or
permission requirements and hints. Add `ActionKitAppKit` when you need live macOS execution.

## Documentation

- [ActionKit API reference](https://swiftpackageindex.com/naviapps/action-kit/documentation/actionkit)
- [ActionKitAppKit API reference](https://swiftpackageindex.com/naviapps/action-kit/documentation/actionkitappkit)

## Basic Usage

Use `ActionKit` to describe an action and inspect its permission requirements:

```swift
import ActionKit

let action = Action.windowPlacement(
  WindowPlacementRequest(
    placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)
  )
)
let permissionSet = ActionPreflight.permissions(for: action)
let permissionHints = ActionPreflight.permissionHints(for: action)
```

Use `ActionKind` when building a catalog before host-supplied input is available:

```swift
import ActionKit

let kind = ActionKind.openURL
let identifier = kind.identifier // "action.workspace.open-url"
let inputDescriptor = kind.inputDescriptor
let inputShape = inputDescriptor.shape // .string
let parameterName = inputDescriptor.parameter?.name // "url"
let exampleInput = inputDescriptor.exampleInput // .string("https://example.com")
let requiresInput = inputDescriptor.requiresInput // true
let capabilities = kind.capabilities
let kindPermissionSet = ActionPreflight.permissions(forKind: kind)
let kindPermissionHints = ActionPreflight.permissionHints(forKind: kind)
```

When hosts create custom input metadata, `ActionInputParameter` returns `nil`
for blank labels or invalid example input, and `ActionInputDescriptor` returns
`nil` when the parameter is missing, unnecessary, or does not match the
descriptor shape.

Use capabilities as conservative host-policy hints:

```swift
import ActionKit

let capabilities = ActionKind.windowPlacement.capabilities

if capabilities.requiresFocusedWindow {
  // Enable only when a focused window is available.
}

if capabilities.requiresInteractiveSelection {
  // Keep the host UI available while the user chooses a target.
}

if capabilities.isDestructive {
  // Ask for confirmation before exposing this action.
}

switch capabilities.retryBehavior {
case .safe:
  // The host may retry after transient failures.
  break
case .contextDependent, .unsafe:
  // Prefer explicit user intent before retrying.
  break
}
```

Create executable actions from the action kind once the required input is available:

```swift
import ActionKit

if let action = ActionKind.openURL.makeAction(input: .string("https://example.com")) {
  // Store or execute the action.
}

let placement = WindowPlacementRequest(
  placement: .grid(
    columns: 2,
    rows: 1,
    column: 0,
    row: 0,
    columnSpan: 1,
    rowSpan: 1
  )
)
if let windowAction = ActionKind.windowPlacement.makeAction(input: .windowPlacement(placement)) {
  // Store or execute the window action.
}
```

Use `ActionCodec` when storing or sending action payloads:

```swift
import ActionKit

let version = ActionCodec.currentVersion
let data = try ActionCodec.encode(Action.openURL("https://example.com"))
let decodedAction = try ActionCodec.decode(data)
```

The encoded envelope uses canonical action identifiers:

```json
{
  "version": 1,
  "action": {
    "kind": "action.workspace.open-url",
    "input": "https://example.com"
  }
}
```

Decoded action envelopes, action payloads, standalone `ActionInput` payloads, input metadata,
capability metadata, permission sets, and execution result payloads reject unknown top-level fields
so stored data matches the documented contract.

Use `ActionKitAppKit` to execute an action from a host app:

```swift
import ActionKitAppKit
import ActionKit

let executor = ActionExecutor()
let request = WindowPlacementRequest(
  placement: .grid(columns: 2, rows: 1, column: 1, row: 0, columnSpan: 1, rowSpan: 1)
)
let outcome = await executor.execute(.windowPlacement(request))
```

`ActionOutcome` includes ordered attempts, `didAttemptFallback`, and the derived final
`ActionResult`. Outcomes always contain at least one recorded attempt; empty internal plans are
reported as an internal-error attempt instead of an empty observation.

## Observability

Live execution returns an `ActionOutcome` instead of a bare success flag. Hosts can inspect:

- `attempts`: ordered execution attempts, including fallback paths
- `didAttemptFallback`: whether the executor had to leave the primary execution path
- `finalResult`: the derived `ActionResult`
- `ActionError`: canonical error codes, diagnostics, and permission context for failures

Create `ActionError` values through the public factories such as
`ActionError.invalidInput(_:)` and `ActionError.permissionDenied(_:)`. The raw error initializer
is intentionally not public so each error code keeps its code-specific payload invariants.

This keeps macOS automation failures visible to the host app without making ActionKit responsible
for analytics, logging storage, or user-facing recovery flows.

## Permissions

ActionKit uses explicit preflight data so host apps can explain permissions before execution:

- Accessibility: key events, fallback key events, and focused-window placement
- Automation: AppleScript-backed system actions
- Screen Recording: screen capture actions through `screencapture`

`ActionExecutorConfiguration` is the host-app integration point for permission hooks and logging.
The default Accessibility check reads the current macOS trust state; host apps should override the
permission hooks when they need onboarding UI or stricter execution behavior.

ActionKit does not depend on PermissionsKit directly. Host apps that already use
`PermissionsKit` can bridge it through
`ActionExecutorConfiguration.Permissions`: keep `ActionPreflight` as the action-specific permission
requirements and hints layer, then use `PermissionsKitAppKit` for macOS permission status,
requests, and System Settings guidance in the configuration hooks.

## Windowing

Focused-window placement and screen movement use ActionKit-owned Codable request payloads and
Codable placement, screen, area, and direction values. `ActionKitAppKit` maps those payloads to
WindowKitAppKit at the live execution boundary:

```swift
import Foundation
import ActionKit

let request = WindowPlacementRequest(
  placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1),
  screen: .containingWindow,
  area: .visible,
  inset: 8
)

let action = Action.windowPlacement(request)
let data = try JSONEncoder().encode(request)
let decoded = try JSONDecoder().decode(WindowPlacementRequest.self, from: data)
```

Decoded windowing request, placement, and screen payloads reject unknown fields and associated
fields that do not match their `kind`, so stored payloads keep one canonical shape for each
windowing value. `ActionWindowPlacement` intentionally exposes only `fill`, `grid`, and
`centered`; fixed half, third, and quarter placements are represented as explicit grid payloads
instead of duplicate public cases. The action catalog follows the same rule: use
`Action.windowPlacement` and `Action.windowMove` with explicit request payloads instead of
input-free fixed placement or screen-move cases.

Host apps remain responsible for Accessibility permission onboarding and for deciding when window
actions should be available.

## FAQ

### Why not just Shortcuts?

Shortcuts is useful for user-authored workflows. ActionKit is for embedded, typed, host-controlled
automation surfaces where an app needs to describe actions, preflight permissions, serialize
payloads, inspect execution semantics, and choose exactly when live macOS APIs are called.

## Development

Run the package check with:

```sh
make check
```

GitHub Actions runs the same check on pull requests and pushes to `main`.

The manifest resolves WindowKit from GitHub by default. Set `WINDOW_KIT_PATH` to test against a
local WindowKit checkout. GitHub Actions uses this override to validate coordinated changes against
the current WindowKit repository.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Release notes are in [CHANGELOG.md](CHANGELOG.md).

## Security

Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).

## License

ActionKit is released under the MIT License. See [LICENSE](LICENSE).
