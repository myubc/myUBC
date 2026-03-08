# myUBC

`myUBC` is an iOS app that aggregates a few student-facing UBC services into a single client:

- food hours and locations
- charger availability from UBC Library equipment pages
- academic calendar deadlines
- campus notifications
- parking availability
- U-Pass reminder shortcuts

The app is intentionally lightweight. It does not depend on a custom backend for the main product flows; instead it fetches public UBC pages directly and normalizes them into app models.

## Architecture

The current codebase is organized around a small shared runtime layer:

- `Core/App` owns programmatic startup, dependency injection, screen factories, and cross-feature routing.
- `Core/Data` owns app-wide caching and landing aggregation.
- `Core/Networking` owns HTTP behavior and retry policy.
- feature `Service` types fetch and parse remote content.
- feature `ViewModel` types expose UI-ready state to controllers.
- `Shared` contains reusable UI, web presentation, and support utilities.
- feature screens and reusable leaf views remain largely XIB-backed, but the runtime shell is no longer storyboard-backed.

Legacy UIKit screens still exist, but the intended direction is service-backed features with explicit parsing and cache boundaries instead of controller-owned networking.

## Project Layout

- [`myUBC`](myUBC): main iOS application target
- [`myUBC/Core`](myUBC/Core): app shell, data, networking, services, and test launch support
- [`myUBC/Shared`](myUBC/Shared): reusable UI, web presentation, and cross-feature support code
- [`myUBC/Vendor`](myUBC/Vendor): vendored third-party code kept outside first-party architecture folders
- [`myUBC/Resources`](myUBC/Resources): assets, configuration, animations, launch screen, and persistence resources
- [`myUBC.widgets`](myUBC.widgets): widget extension
- [`myUBCTests`](myUBCTests): parser, runtime, and feature view/component tests
- [`myUBCUITests`](myUBCUITests): mocked end-to-end UI workflow tests
- [`Scripts`](Scripts): local parsing utilities

## Development

Requirements:

- Xcode 16 or newer
- iOS 18 SDK or the SDK version required by the project settings

Open the project:

```bash
open Sources/myUBC.xcodeproj
```

Useful local commands:

```bash
xcodebuild -project Sources/myUBC.xcodeproj -scheme myUBC -showdestinations
xcodebuild -project Sources/myUBC.xcodeproj -scheme myUBC -destination 'platform=iOS Simulator,id=<SIMULATOR_ID>' test
```

If you use SwiftLint locally, a repository config is provided at [`Sources/.swiftlint.yml`](Sources/.swiftlint.yml).

## Community

- Bug reports: [GitHub Issues](https://github.com/myubc/myUBC/issues/new/choose)
- Feature requests: [GitHub Issues](https://github.com/myubc/myUBC/issues/new/choose)
- Questions and support: [GitHub Discussions](https://github.com/myubc/myUBC/discussions)
- Release notes: [Announcements](https://github.com/myubc/myUBC/discussions/categories/announcements)

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md), [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md), and [`SECURITY.md`](SECURITY.md) before opening changes or reporting vulnerabilities.

## Distribution

The production build is available on the [App Store](https://apps.apple.com/ca/app/myubc-made-for-ubc-students/id1498544052).

## Legal

Legal and privacy documents are linked from [`Legal.md`](Legal.md).
