# Contributing

Thank you for your interest in improving ActionKit.

## Scope

ActionKit focuses on describing, preflighting, and executing common macOS actions. Host-app
workflows such as permission onboarding UI, shortcut registration, persistence, analytics,
telemetry, and product policy should stay outside this package.

Please keep changes focused. Avoid bundling unrelated refactors, formatting-only rewrites, and
behavior changes in the same pull request.

## Development

Local development commands use `make`.

Run the full local check before opening a pull request:

```sh
make check
```

This matches the CI gate: formatting lint and strict-concurrency tests.

For focused local work, you can run checks separately:

```sh
make format
make lint
make test
```

## Pull Requests

Before submitting a pull request:

- Keep the public API surface minimal and documented.
- Add or update tests for behavior changes.
- Update README, DocC, or `CHANGELOG.md` when user-facing behavior changes.
- Do not commit generated build output, dependency caches, editor state, local tool state, secrets,
  or private logs.

## Security

Do not report vulnerabilities in public issues or pull requests. Follow [SECURITY.md](SECURITY.md)
instead.
