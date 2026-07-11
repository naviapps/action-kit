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
  ActionKit-owned Codable placement, screen, area, and direction values

## Responsibility Boundary

ActionKit owns action models, canonical identifiers, input descriptors,
capability metadata, permission preflight hints, JSON envelopes, focused-window
request values and their Codable payload values, and execution result models.

ActionKit does not request permissions, post events, run commands, execute
AppleScript, open URLs, control windows, collect analytics, transmit data, or
persist action history. Those live integrations are provided by
`ActionKitAppKit` or the host app.

Action identifiers are the canonical serialization names for the current action catalog. Use
``ActionKind/identifier`` and ``ActionCodec`` payloads for persistence, IPC, and tool bindings
instead of relying on enum case names as external protocol strings.

Use ``ActionKind`` when building a picker or command catalog before input is available:

```swift
import ActionKit

let kind = ActionKind.openURL
let identifier = kind.identifier
let inputDescriptor = kind.inputDescriptor
let inputShape = inputDescriptor.shape
let parameterName = inputDescriptor.parameter?.name
let exampleInput = inputDescriptor.exampleInput
let requiresInput = inputDescriptor.requiresInput
let capabilities = kind.capabilities
let permissionHints = ActionPreflight.permissionHints(forKind: kind)
```

When hosts create custom input metadata, ``ActionInputParameter`` returns `nil`
for blank labels or invalid example input, and ``ActionInputDescriptor``
returns `nil` when the parameter is missing, unnecessary, or does not match the
descriptor shape.

Use capabilities as conservative host-policy hints for focused-window
availability, interactive selection, destructive actions, and retry behavior.

Create an ``Action`` once the host has the required input:

```swift
import ActionKit

if let action = ActionKind.openURL.makeAction(input: .string("https://example.com")) {
  // Store or execute the action.
}
```

Decoded action envelopes, action payloads, standalone ``ActionInput`` payloads, input metadata,
capability metadata, permission sets, and execution result payloads reject unknown top-level fields
so stored data matches the documented contract.

Live execution reports ``ActionOutcome`` values with ordered ``ActionAttempt`` records,
``ActionResult`` summaries, and ``ActionError`` diagnostics. Windowing actions use explicit
``WindowPlacementRequest`` and ``WindowMoveRequest`` payloads instead of duplicate fixed-placement
catalog cases.

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

- ``ActionWindowPlacement``
- ``ActionWindowScreenTarget``
- ``ActionWindowScreenArea``
- ``ActionWindowScreenCycleDirection``
- ``WindowPlacementRequest``
- ``WindowMoveRequest``
