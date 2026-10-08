# Screenshots

Use this guide to generate App Store screenshots for iOS, iPadOS, and tvOS.

> [!IMPORTANT]
> Each simulator is erased before its screenshots are captured.

## Running

```bash
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 fastlane screenshots
```

Options:

- `platform`: `ios`, `ipados`, or `tvos`. Runs all platforms when omitted.
- `process`: `false` to skip framing and cards.
- `server`, `username`, `password`: the Jellyfin server to sign in to. Defaults to the [Jellyfin demo server](https://demo.jellyfin.org/stable).
- `iosDevice`, `ipadosDevice`, `tvosDevice`: the simulator device type to use, as listed by `xcrun simctl list devicetypes`.
  - Example: `iosDevice:iPhone-16-Pro`

Default devices:

- iOS: `iPhone-18-Pro`
- iPadOS: `iPad-Pro-13-inch-M5-12GB`
- tvOS: `Apple-TV-4K-3rd-generation-4K`

A simulator is created on the newest runtime if none exists for the device type.

> [!NOTE]
> Screenshots are only framed when `Scripts/Screenshots/Frames` has a frame matching their size. Otherwise, cards use the unframed screenshot.

## Output

Screenshots are written to `Documentation/Screenshots/<Platform>/<Language>/`:

- `Raw`: the screenshots as captured
- `Framed`: the screenshots inside a device frame (iOS and iPadOS)
- `Cards`: App Store cards with a caption over the framed screenshot

## Structure

- `Screenshots/ScreenshotTests.swift`: the flow
- `Screenshots/Support/Screenshot.swift`: each screenshot with its headline and subtitle
- `Screenshots/Robots`: one robot per screen, shared by iOS and tvOS
- `Scripts/Screenshots/ProcessScreenshots.swift`: builds `Framed` and `Cards`
- `Scripts/Screenshots/Frames`: device frames, named by screenshot size (`<width>x<height>-frame.png`, optional `-mask.png`)
- `Scripts/Screenshots/Fonts`: Figtree and Inter

## Adding a screenshot

1. Add `screenshotHeadline<Name>` and `screenshotSubtitle<Name>` to `Translations/en.lproj/Localizable.strings`.
2. Add a case to `Screenshot` and return those `L10n` strings from `headline` and `subtitle`.
3. Navigate to the screen with the robots and call `.screenshot(.<name>)`.
