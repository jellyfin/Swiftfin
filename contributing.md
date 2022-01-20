# Contributing to Swiftfin

> Thank you for your interest in contributing to the Jellyfin (Swiftfin) project! This page and its children describe the ways you can contribute, as well as some of our policies. This should help guide you through your first Issue or PR.

> Even if you can't contribute code, you can still help Jellyfin (Swiftfin)! The two main things you can help with are testing and creating issues. Contributing to code, documentation, ..., and other non-code components are all outlined in the sections below.

## Setup

Fork the Swiftfin repo and install the necessary CocoaPods with Xcode 13:

```bash
# install Cocoapods (if not installed)
$ sudo gem install cocoapods

# install dependencies
$ pod install

# open workspace and build
$ open Swiftfin.xcworkspace
```

## Git Flow

Swiftfin follows the same Pull Request Guidelines as outlined in the [Jellyfin Pull Request Guidelines](https://jellyfin.org/docs/general/contributing/development.html#pull-request-guidelines).

If your Pull Request relates to an Issue, mention the issue correctly in your PR description.

[SwiftFormat](https://github.com/nicklockwood/SwiftFormat) is our linter. You can run `swiftformat .` in the project directory or install SwiftFormat's Xcode extension.

The following must pass in order for a PR to be merged:
- automated `iOS` and `tvOS` builds must succeed
- developer account cannot be attached
- SwiftFormat linting check must pass
- new strings that are not part of an experimental feature must be localized
- correct label(s) are attached, if applicable

Labeling PRs with `enhancement`, `bug`, or `crash` will allow the PR to be tracked in GitHub's [automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes). Small fixes (like minor UI adjustments) or non-user facing issues (like developer project clean up) should also have the `ignore-for-release` label since many PRs may be similar. If you think that no labels are required, that is acceptable.

### Documentation
Documentation for advanced or complex features and other implementation reasoning is encouraged so that future developers may have insights and a better understand of the application. `// MARK:` comments are encouraged for organization, maintainability, and ease of navigation in Xcode's Minimap.

## Architecture

Swiftfin is developed using SwiftUI with some UIKit components where deemed necessary, as SwiftUI is still in relatively early development and limiting. Swiftfin consists of both the iOS and tvOS Jellyfin clients with a shared underlying structure where each client has their own respective views. Due to this architecture, working on both clients at once may be necessary.

Playback is done with [VLCKit](https://code.videolan.org/videolan/VLCKit) for its great codec support. Becoming familiar with VLCKit will be necessary for video playback development or relating features.

## Design

While there are no design guidelines for UI/UX features, Swiftfin has the goal to use native SwiftUI/UIKit components while adhering to a Jellyfin theme. If your feature creates new UI/UX components, you are welcome to introduce a general design that may receive feedback during the PR process or may be re-designed later on.

User customizable UI/UX features are welcome and intended, however not all customization may be accepted for code maintainability and to also establish a specific Swiftfin design. Taking inspiration, but not always copying, from other applications is encouraged.

## New Features

If you would like to develop a new feature or `Developer` issue, create an issue with a description of the feature so that a discussion can be made for its possibility, whether it belongs in Swiftfin, and finally its general implementation. Leave a comment when you start work on an approved feature so that duplicate work among developers doesn't conflict.

## Other Code Work

Other code work like bug fixes, issues with `Developer` tags, and localization and accessibility efforts are welcome to be picked up at any time. Just leave a comment when you start work on a bug fix or `Developer` issue.

If you notice undesirable behavior or would like to make a UI/UX tweak, create an issue or ask in the iOS Matrix/Discord channel and a discussion will be made.

If you have a question about any existing implementations, ask the iOS Matrix/Discord channel for developer insights.

## Intended Behaviors Due to Technical Limitations

The following behaviors are intended due to current technical limitations with VLCKit:

- Pausing playback when app is backgrounded as VLCKit pauses video output at the same time
- Audio delay when starting playback and un-pausing, may be fixed in VLCKit v4
