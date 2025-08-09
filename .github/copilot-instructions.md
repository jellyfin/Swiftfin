# Copilot Instructions for Swiftfin

## Project Overview
- **Swiftfin** is a modern video client for the [Jellyfin](https://github.com/jellyfin/jellyfin) media server, built with Swift and SwiftUI for iOS and tvOS.
- The codebase is split into shared backend logic and platform-specific (iOS/tvOS) views. Most business logic is shared; UI is separated by platform.
- Playback is handled by [VLCKit](https://code.videolan.org/videolan/VLCKit) for broad codec/container support. Native (AVKit) playback is also available for some use cases.

## Key Directories
- `Swiftfin/` and `Swiftfin tvOS/`: App entry points, platform-specific views, and resources.
- `Shared/`: Core business logic, models, services, and view models shared across platforms.
- `Resources/`: App icons, SVGs, and other static assets.
- `Documentation/`: Developer docs, player feature matrix, and contribution guidelines.
- `Translations/`: Localizable resources for multiple languages.

## Build & Development
- Use **Xcode 15+**. Install dependencies with:
  ```sh
  brew install carthage swiftformat swiftgen
  carthage update --use-xcframeworks
  ```
- Use `XcodeConfig/DevelopmentTeam.xcconfig` to set your development team and bundle identifier for local builds.
- Lint with `swiftformat .` before submitting PRs.
- Automated builds for iOS and tvOS must pass for PRs to be merged.
- Always use Build command: `xcodebuild -scheme "Swiftfin" -destination "platform=iOS Simulator,name=iPhone 16,OS=18.5" build`


## Architecture & Patterns
- **SwiftUI** is used for UI; UIKit is used only where necessary.
- **Service/Coordinator pattern**: Business logic and navigation are separated from views. See `Shared/Services/` and `Shared/Coordinators/`.
- **ViewModels**: All stateful logic for views is in `Shared/ViewModels/`.
- **MARK:** comments are encouraged for code organization.
- **Localization**: All user-facing strings must be localized unless part of an experimental feature.

## Player Integration
- Two playback engines: `Swiftfin (VLCKit)` and `Native (AVKit)`. See `Documentation/players.md` for feature and compatibility matrix.
- VLCKit is required for advanced codec/container support. Some features (e.g., subtitle/audio track selection) are only available in VLCKit.
- Known limitations: Audio delay on playback start/unpause (VLCKit), limited subtitle/audio track selection in AVKit.

## Contribution Workflow
- Fork, install dependencies, and use a feature branch.
- Reference related issues in PRs. Use labels (`enhancement`, `bug`, etc.) for release note tracking.
- For new features, open a Feature Request and discuss before starting large changes.
- Documentation for complex features is encouraged.

## External Integrations
- **Carthage**: For dependency management (see `Cartfile`).
- **SwiftFormat**: For linting.
- **SwiftGen**: For code generation from assets.
- **VLCKit**: For media playback.
- **Jellyfin server**: Required for app functionality.

## Testing & Debugging
- Automated builds run for iOS and tvOS.
- For player debugging, be familiar with VLCKit and its limitations.
- Use the Matrix/Discord channels for support and questions.

## References
- [Contribution Guidelines](../Documentation/contributing.md)
- [Player Feature Matrix](../Documentation/players.md)
- [Jellyfin Project](https://jellyfin.org/)

---

*Update this file as project structure or workflows evolve. For questions, see the documentation or ask in the community channels.*
