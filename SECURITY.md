# Security Policy

## Supported Versions

Security updates are provided for the latest released version.

## Reporting a Vulnerability

Report security issues through GitHub private vulnerability reporting for this repository.

Do not open a public issue, pull request, or discussion for vulnerabilities, suspected credential
exposure, privacy-sensitive behavior, or issues that could expose private user data.

If private vulnerability reporting is unavailable, open a public issue asking for a private
security contact channel. Do not include vulnerability details, exploit steps, logs, secrets,
tokens, private keys, personal data, local paths, private app metadata, or app-specific internal
references.

For private reports, include:

- Affected package version or commit
- Affected dependency versions if relevant
- A clear description of the behavior
- Reproduction steps or a minimal proof of concept
- Expected impact
- Affected public API, target, or subsystem

Use placeholders instead of secrets, tokens, private keys, personal data, local paths, private app
metadata, or app-specific internal references.

We will acknowledge valid reports as soon as practical and coordinate fixes before public
disclosure.

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
