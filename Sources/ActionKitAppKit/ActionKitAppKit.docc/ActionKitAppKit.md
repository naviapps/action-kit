# ``ActionKitAppKit``

Execute ActionKit actions using live macOS integrations.

## Overview

`ActionKitAppKit` provides the package's default live executor for host apps. It translates
`ActionKit` actions into AppKit, Core Graphics, AppleScript, Shortcuts URL, screen capture, and
WindowKitAppKit operations.

The main entry point is ``ActionExecutor``:

```swift
import ActionKitAppKit
import ActionKit

let executor = ActionExecutor()
let outcome = await executor.execute(.copy)
```

Host apps should provide an ``ActionExecutorConfiguration`` when they need app-specific permission
hooks, recovery UI, or logging. The package does not own user onboarding, shortcut registration,
persistence, analytics, or telemetry.
The default Accessibility hook reads the current macOS trust state without prompting.
Use ``ActionExecutorConfiguration/LogLevel`` to decide which executor diagnostics are forwarded.

## Responsibility Boundary

ActionKitAppKit owns the default live macOS executor for ActionKit actions,
including AppKit, Core Graphics, AppleScript, Shortcuts URL, screen capture, and
WindowKitAppKit integration paths.

Host apps remain responsible for permission onboarding, user-facing prompts,
shortcut registration, recovery UI, persistence, analytics, telemetry, privacy
disclosures, and deciding which actions are exposed.

## Permissions

Live execution may require Accessibility, Automation, or Screen Recording depending on the action.
Use `ActionPreflight.permissionHints(for:)` before execution when the host app needs to explain
permission requirements to users.

ActionKitAppKit keeps permission UX injectable instead of depending on a specific onboarding
library. Apps that use `PermissionsKit` can call
`PermissionsKitAppKit` from ``ActionExecutorConfiguration/Permissions`` hooks to check status,
request supported permissions, or open System Settings while keeping ActionKit's permission model
action-specific.

## Shortcuts Catalog

``ShortcutsCatalog`` lists system shortcut names with bounded process I/O. It
never executes a shortcut. Hosts choose deadline/output limits, own picker state
and decide whether names may appear in diagnostics. Cancellation throws
`CancellationError`; other failures use ``ShortcutsCatalogError`` without raw
output. The child process is stopped and reaped before cancellation or failure
returns. The default limit is one MiB and the default timeout is ten seconds.

## Topics

### Execution

- ``ActionExecutor``
- ``ActionExecutor/init(configuration:)``
- ``ActionExecutorConfiguration``
- ``ActionExecutorConfiguration/init(permissions:log:)``
- ``ActionExecutorConfiguration/Permissions``
- ``ActionExecutorConfiguration/Permissions/init(ensureAccessibility:ensureAutomation:onAutomationDenied:onScreenRecordingRequired:)``
- ``ActionExecutorConfiguration/LogLevel``

### Shortcuts Catalog

- ``ShortcutsCatalog``
- ``ShortcutsCatalog/init(timeout:maximumOutputByteCount:)``
- ``ShortcutsCatalog/shortcutNames()``
- ``ShortcutsCatalogError``
