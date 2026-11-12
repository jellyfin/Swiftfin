# Capsule Styles TV

A standalone tvOS app with one vertical list of capsule buttons. It shows all five control sizes, selection tint, inactive selection, custom focus tint, and the disabled state. Use the remote to move focus and press Select to toggle selection.

Open `CapsuleStylesTV.xcodeproj`, choose the `CapsuleStylesTV` scheme and an Apple TV simulator, then Run. Requires Xcode with the tvOS 26.1 SDK or newer. No server or account is needed.

The project references the capsule style, horizontal label style, adaptive layout, and glass rendering files directly from `../../Shared`. Changes to those files are reflected when rebuilding. `Sources/SampleSupport.swift` supplies only the minimal app infrastructure needed to compile them independently.

To regenerate the project after editing `project.yml`, run `xcodegen generate --spec project.yml` from this directory.
