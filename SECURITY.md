# Security Policy

## Supported Versions

Security fixes are tracked on the default branch. After public releases are available, fixes are
provided for the latest released version.

## Reporting a Vulnerability

Report security issues through GitHub's private vulnerability reporting for this repository.

Do not open a public issue or pull request for vulnerabilities, suspected credential exposure,
privacy-sensitive automation behavior, or action execution issues that could expose private data.

If private vulnerability reporting is unavailable, open a public issue asking for a private contact
channel. Do not include vulnerability details, exploit steps, logs, secrets, tokens, local paths,
private app metadata, window titles, process identifiers, or personal data.

When reporting an issue, include:

- Affected package version or commit
- A clear description of the behavior
- Reproduction steps or a minimal proof of concept
- Expected impact
- Affected action, permission, AppleScript, shortcut, screen capture, or windowing behavior

We will acknowledge valid reports as soon as practical and coordinate fixes before public
disclosure.

For non-security bugs, use the public bug report template.

## Scope

Security-sensitive areas include:

- Accessibility-backed key events and focused-window control
- AppleScript and Automation permission flows
- Screen capture execution and Screen Recording permission behavior
- File URLs and application launch paths supplied by host apps
- Logging or diagnostics that include local paths, app names, bundle identifiers, process
  identifiers, window metadata, or action errors

ActionKit does not collect, transmit, or persist action data by itself. Host applications are
responsible for permission onboarding, logging, telemetry, privacy disclosures, and deciding which
actions are available to users.
