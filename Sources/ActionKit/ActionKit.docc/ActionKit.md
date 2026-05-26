# ``ActionKit``

Describe macOS actions, inspect permission requirements, and serialize action payloads without
running live system integrations.

## Overview

`ActionKit` contains the package's platform-model layer. Use it when a host app needs to store,
decode, and inspect actions before deciding whether to execute them.

The core target includes:

- ``Action``, ``ActionKind``, and ``ActionCategory`` for supported actions and action-kind metadata
- ``ActionInput``, ``ActionInputShape``, ``ActionInputDescriptor``, and
  ``ActionInputParameter`` for host-supplied values and input requirements
- ``ActionKindCapabilities`` and ``ActionRetryBehavior`` for conservative host-policy metadata
- ``ActionCodec`` for versioned JSON action envelopes
- ``ActionPreflight`` for converting actions into permission requirements and hints
- ``ActionResult``, ``ActionError``, ``ActionAttempt``, and ``ActionOutcome`` for execution
  reporting
- ``WindowPlacementRequest`` and ``WindowMoveRequest`` for focused-window actions backed by
  WindowKit value types

`ActionKit` does not request permissions, post events, run commands, execute AppleScript, open
URLs, or control windows. Those live integrations are provided by `ActionKitAppKit`.

Typical integrations include launcher apps with curated action catalogs, keyboard utilities that
preflight focused-app or focused-window actions, and local assistants that serialize suggested
actions before asking the host app to execute them.

A typical host flow is: build an ``ActionKind`` catalog, inspect input descriptors and capabilities,
preflight permission hints, encode or decode an ``ActionCodec`` envelope, execute through
`ActionKitAppKit`, then observe the returned ``ActionOutcome``.

Stable action identifiers are intended to remain compatible across minor releases. Use
``ActionKind/identifier`` and ``ActionCodec`` payloads for persistence, IPC, and tool bindings
instead of relying on enum case names as external protocol strings.

Use ``ActionKind`` when building a picker or command catalog before input is available:

```swift
let kind = ActionKind.openURL
let identifier = kind.identifier
let inputShape = kind.inputShape
let inputDescriptor = kind.inputDescriptor
let parameterName = inputDescriptor.parameter?.name
let exampleInput = inputDescriptor.exampleInput
let requiresInput = inputDescriptor.requiresInput
let capabilities = kind.capabilities
let permissionHints = ActionPreflight.permissionHints(forKind: kind)
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

Create an executable ``Action`` once the host has the required input:

```swift
if let action = ActionKind.openURL.action(input: .string("https://example.com")) {
  // Store or execute the action.
}
```

Use ``ActionCodec`` for versioned JSON envelopes:

```swift
let version = ActionCodec.currentVersion
let data = try ActionCodec.encode(Action.openURL("https://example.com"))
let decodedAction = try ActionCodec.decode(data)
```

The encoded envelope stores stable action identifiers:

```json
{
  "version": 1,
  "action": {
    "kind": "action.workspace.open-url",
    "input": "https://example.com"
  }
}
```

Live execution returns ``ActionOutcome`` instead of a bare success flag. Hosts can inspect ordered
``ActionAttempt`` values, fallback usage, the derived ``ActionResult``, and ``ActionError``
diagnostics without making ActionKit responsible for analytics, log storage, or user-facing
recovery flows.

Shortcuts remains useful for user-authored workflows. ActionKit is for embedded, typed,
host-controlled automation surfaces where an app needs to describe actions, preflight permissions,
serialize payloads, inspect execution semantics, and choose when live macOS APIs are called.

## Topics

### Actions

- ``Action``
- ``ActionKind``
- ``ActionCategory``
- ``ActionKindCapabilities``
- ``ActionRetryBehavior``
- ``ActionInput``
- ``ActionInputShape``
- ``ActionInputDescriptor``
- ``ActionInputParameter``

### Preflight

- ``ActionPreflight``
- ``ActionPermission``
- ``ActionPermissionHint``
- ``ActionPermissionReason``
- ``ActionPermissionSet``

### Results

- ``ActionResult``
- ``ActionOutcome``
- ``ActionAttempt``
- ``ActionError``
- ``ActionErrorCode``
- ``ActionSkipReason``

### Coding

- ``ActionCodec``
- ``ActionCodecError``

### Windowing

- ``WindowPlacementRequest``
- ``WindowMoveRequest``
