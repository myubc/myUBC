# Contributing to myUBC

## Before You Start

- Use issues for bugs and feature requests.
- Use discussions for usage questions or general support.
- Keep pull requests focused. Small, reviewable changes move faster than mixed refactors.

## Local Setup

```bash
open Sources/myUBC.xcodeproj
```

Run the main automated checks before opening a pull request:

```bash
xcodebuild -project Sources/myUBC.xcodeproj -scheme myUBC -showdestinations
xcodebuild -project Sources/myUBC.xcodeproj -scheme myUBC -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' test
```

Optional linting:

```bash
swiftlint lint --config Sources/.swiftlint.yml Sources/myUBC Sources/myUBCTests Sources/myUBCUITests
```

## Pull Request Expectations

- Describe the user-facing change and the technical approach.
- Link the related issue when one exists.
- Add or update tests for behavior changes.
- Update fixtures or snapshots when parser or UI expectations change.
- Avoid unrelated formatting churn in the same pull request.

## Scope Guidelines

- Parser changes should include fixture-backed tests where practical.
- UI behavior changes should include targeted tests when practical.
- Changes under `Sources/myUBC/Vendor` should be avoided unless you are intentionally updating vendored code.

## Review Process

Maintainers may request test coverage, narrower scope, or follow-up cleanup before merge. Security-sensitive changes may be handled outside the normal public PR flow; see [`SECURITY.md`](SECURITY.md).
