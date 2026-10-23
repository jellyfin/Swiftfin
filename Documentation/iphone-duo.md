# iPhone Duo

Build the `Swiftfin` scheme with Xcode 27.1 and the iOS 27.1 SDK to adopt iPhone Duo's adaptive system bars and division-aware player layout. The minimum deployment version remains unchanged.

Build and TestFlight workflows select Xcode 27.1 on GitHub's `xcode-27` runners. PR validation also selects that toolchain explicitly. The iOS 27.1 player APIs remain guarded at runtime for devices running older supported iOS versions.

## Adaptive layout

Library, poster, episode, and user grids use the current horizontal size class, including regular-width iPhone windows. Poster images derive their height from the available width and keep labels at their natural height, so a taller collection cell cannot stretch artwork into adjacent columns. Collection layouts remeasure when their width changes.

The app supports portrait and landscape. Enhanced item details retain the same scroll-view hierarchy when the width changes, preserving the selected item and scroll state. Compact-height headers use a shorter image area to keep Play visible. Header artwork extends to the top within the horizontal safe area; overview text and system side controls retain their own background areas.

Browsing grids, search results, descriptions, and filter controls respect horizontal safe areas. Collection views account for vertical safe-area insets explicitly and apply horizontal spacing once. Toasts measure the attached window's current safe area, including independent leading and trailing insets. Native navigation and tab bars retain their automatic system placement.

## Player divisions

The custom player uses size classes to select its controls layout. On iOS 27.1, it reads active division reserved regions and responds to hinge updates without replacing the player controller:

- A horizontal division places video above the reserved region and controls below it.
- A vertical division keeps video and controls together in the larger unobstructed pane.
- When no active division applies, the existing full-window layout is restored.

Reserved-region frames already contain the system's interaction margins. Constraints use those frames directly and also respect the safe area for overlay actions.

## Build and verify

Follow [the contribution guide](contributing.md) for dependencies, signing, and the project's recommended Xcode version. To exercise the iOS 27.1 integration, select **Swiftfin → iPhone Duo (iOS 27.1)** in Xcode. Simulator signing must remain enabled so Keychain-backed sign-in has a simulated application identity. Physical-device builds require normal Apple development provisioning.

Use Device Hub to exercise Closed and Open displays in portrait and both landscape directions, followed by book and tabletop poses. With a configured Jellyfin server:

- Keep a library scrolled and an item selected while changing display size; confirm navigation and scroll state continue.
- Check poster spacing, header bounds, filter scrolling, Back, tabs, and Play around cameras, system bars, and the fold.
- During playback, keep a supplement open and verify playback continues while video, controls, and supplements resize.
- Show a toast before and after rotation and display changes.
- Check larger accessibility text sizes, VoiceOver, and right-to-left layout.

Simulator browsing and build results do not establish playback continuity or behavior on physical hardware.

## Apple guidance

- [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo)
- [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)
- [Strike a pose with adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/)
- [Raise the bar with iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111462/)
