# Contributing to Swiftfin

> Thank you for your interest in contributing to the Jellyfin (Swiftfin) project! This page and its children describe the ways you can contribute, as well as some of our policies. This should help guide you through your first Issue or PR.

> Even if you can't contribute code, you can still help Jellyfin (Swiftfin)! The two main things you can help with are testing and creating issues. Contributing to code, ..., and other non-code components are all outlined in the sections below.

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

Pull Requests must be created from branch that is _**not**_ your fork's `main` branch. This is to prevent many potential problems that come from unnecessary or irrelevant commits and rebasing your fork.

If your Pull Request relates to an Issue, link the issue or mention it in the Issue itself.

Pull Requests must pass the automated `iOS` and `tvOS` builds in order to be merged and cannot have your developer account attached.

Swiftfin follows the same Pull Request Guidelines as outlined in the [official Jellyfin contribution guidelines](https://jellyfin.org/docs/general/contributing/development.html#pull-request-guidelines).

## Architecture

Swiftfin is developed using SwiftUI with some UIKit components where deemed necessary, as SwiftUI is still in relatively early development. Swiftfin consists of both the iOS and tvOS Jellyfin clients with a shared general underlying structure where each client has their own respective views. Because of this architecture, keep in mind while developing you may have to work for both clients.

Playback is done using [VLCKit](https://code.videolan.org/videolan/VLCKit) for its great codec support.

While there are no design guidelines for UI/UX features, Swiftfin has the goal to use native SwiftUI components with specific theming to Jellyfin. If your feature creates new UI/UX components, you are welcome to introduce a general design that may receive feedback during the PR process or may be re-designed later on. Some UI/UX features are intended to be user customizable but not every item should be to keep to some idea of Swiftfin's own design. Taking inspiration, but not always copying, from other applications is encouraged.

## New Features

If you would like to develop a new feature, create an issue with a description of the feature such that a discussion can be made for its possibility, whether it belongs in Swiftfin, and finally its general implementation. Leave a comment when you start work on an approved feature such that duplicate work among developers doesn't conflict.

## Other Code Work

Other code work like bug fixes, issues with `Developer` tags, and localization efforts are welcome to be picked up anytime. Just leave a comment when you start work on a bug fix or `Developer` issue.

If you notice undesirable behavior or would like to make a UI/UX tweak, create an issue or ask in the iOS Matrix/Discord channel and a discussion will be made.

If you have a question about any existing implementations, ask the iOS Matrix/Discord channel for developer insights.
