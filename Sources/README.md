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

- Xcode 16+
- iOS SDK matching the project settings
- SwiftLint if you want to run the local lint checks

Open either:

- [`myUBC.xcworkspace`](myUBC.xcworkspace) if you are working with CocoaPods
- [`myUBC.xcodeproj`](myUBC.xcodeproj) if you are using the newer package-based setup

## Quality Gates

- parser fixtures live under [`myUBCTests/Fixtures`](myUBCTests/Fixtures)
- run `swiftlint lint`
- run the `myUBCTests` target for deterministic component/runtime checks
- run `LandingScreenUITests` for mocked workflow coverage on the landing/reminder flow
