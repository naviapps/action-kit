# ActionKit

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/naviapps/action-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/naviapps/action-kit/actions/workflows/ci.yml)
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
     - stable action identifiers
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

Stable action identifiers are intended to remain compatible across minor releases. Use
`ActionKind.identifier` and `ActionCodec` payloads for persistence, IPC, and tool bindings instead
of relying on enum case names as external protocol strings.

## Responsibility Boundary

ActionKit describes, preflights, and executes actions. Host apps are responsible for:

- permission onboarding and user-facing prompts
- shortcut registration, gesture recognition, menus, and UI
- persistence, analytics, telemetry, and privacy policy choices
- deciding which actions are exposed to users
- handling app-specific recovery when macOS denies access

The package does not request permissions, collect analytics, transmit data, or persist action
history by itself.

## Requirements

- macOS 13 or later
- Swift 5.10 or later

## Installation

Add this package to your Swift Package dependencies:

```swift
.package(url: "https://github.com/naviapps/action-kit.git", from: "1.0.0")
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

let action = Action.windowLeftHalf
let permissionSet = ActionPreflight.permissions(for: action)
let permissionHints = ActionPreflight.permissionHints(for: action)
```

Use `ActionKind` when building a catalog before host-supplied input is available:

```swift
let kind = ActionKind.openURL
let identifier = kind.identifier // "action.workspace.open-url"
let inputShape = kind.inputShape // .string
let inputDescriptor = kind.inputDescriptor
let parameterName = inputDescriptor.parameter?.name // "url"
let exampleInput = inputDescriptor.exampleInput // .string("https://example.com")
let requiresInput = inputDescriptor.requiresInput // true
let capabilities = kind.capabilities
let kindPermissionSet = ActionPreflight.permissions(forKind: kind)
let kindPermissionHints = ActionPreflight.permissionHints(forKind: kind)
```

Use capabilities as conservative host-policy hints:

```swift
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
case .contextDependent, .unsafe:
  // Prefer explicit user intent before retrying.
}
```

Create executable actions from the action kind once the required input is available:

```swift
if let action = ActionKind.openURL.action(input: .string("https://example.com")) {
  // Store or execute the action.
}

let placement = WindowPlacementRequest(placement: .leftHalf)
if let windowAction = ActionKind.windowPlacement.action(input: .windowPlacement(placement)) {
  // Store or execute the window action.
}
```

Use `ActionCodec` when storing or sending action payloads:

```swift
let version = ActionCodec.currentVersion
let data = try ActionCodec.encode(Action.openURL("https://example.com"))
let decodedAction = try ActionCodec.decode(data)
```

The encoded envelope uses stable action identifiers:

```json
{
  "version": 1,
  "action": {
    "kind": "action.workspace.open-url",
    "input": "https://example.com"
  }
}
```

Use `ActionKitAppKit` to execute an action from a host app:

```swift
import ActionKitAppKit
import ActionKit

let executor = ActionExecutor()
let outcome = await executor.execute(.windowRightHalf)
```

`ActionOutcome` includes ordered attempts, `didAttemptFallback`, and the derived final
`ActionResult`.

## Observability

Live execution returns an `ActionOutcome` instead of a bare success flag. Hosts can inspect:

- `attempts`: ordered execution attempts, including fallback paths
- `didAttemptFallback`: whether the executor had to leave the primary execution path
- `finalResult`: the derived `ActionResult`
- `ActionError`: stable error codes, diagnostics, and permission context for failures

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
[`PermissionsKit`](https://github.com/naviapps/permissions-kit) can bridge it through
`ActionExecutorConfiguration.Permissions`: keep `ActionPreflight` as the action-specific permission
requirements and hints layer, then use `PermissionsKitAppKit` for macOS permission status,
requests, and System Settings guidance in the configuration hooks.

## Windowing

Focused-window placement and screen movement use WindowKit request types:

```swift
import ActionKit
import WindowKit

let request = WindowPlacementRequest(
  placement: .leftHalf,
  screen: .containingWindow,
  area: .visible,
  inset: 8
)

let action = Action.windowPlacement(request)
```

Live execution is provided by `ActionKitAppKit` through WindowKitAppKit. Host apps remain
responsible for Accessibility permission onboarding and for deciding when window actions should be
available.

## FAQ

### Why not just Shortcuts?

Shortcuts is useful for user-authored workflows. ActionKit is for embedded, typed, host-controlled
automation surfaces where an app needs to describe actions, preflight permissions, serialize
payloads, inspect execution semantics, and choose exactly when live macOS APIs are called.

## Development

Local development commands use `make`.

Run all local checks:

```sh
make check
```

For focused local work, run `make lint` or `make test`. The GitHub Actions CI runs the same
formatting lint and strict-concurrency tests on pull requests and pushes to `main`.

## License

ActionKit is released under the MIT License. See [LICENSE](LICENSE).
