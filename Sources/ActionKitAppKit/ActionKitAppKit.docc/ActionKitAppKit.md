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

## Permissions

Live execution may require Accessibility, Automation, or Screen Recording depending on the action.
Use `ActionPreflight.permissionHints(for:)` before execution when the host app needs to explain
permission requirements to users.

ActionKitAppKit keeps permission UX injectable instead of depending on a specific onboarding
library. Apps that use [PermissionsKit](https://github.com/naviapps/permissions-kit) can call
`PermissionsKitAppKit` from ``ActionExecutorConfiguration/Permissions`` hooks to check status,
request supported permissions, or open System Settings while keeping ActionKit's permission model
action-specific.

## Topics

### Execution

- ``ActionExecutor``
- ``ActionExecutorConfiguration``
- ``ActionExecutorConfiguration/Permissions``
- ``ActionExecutorConfiguration/LogLevel``
