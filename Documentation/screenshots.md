# Screenshots

Use this guide to generate App Store screenshots for iOS, iPadOS, and tvOS from the [Jellyfin demo server](https://demo.jellyfin.org/stable).

> [!IMPORTANT]
> Each simulator is erased before its screenshots are captured.

## Running

```bash
LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 fastlane screenshots
```

Options:

- `platform`: `ios`, `ipados`, or `tvos`. Runs all platforms when omitted.
- `process`: `false` to skip framing and cards.
- `iosDevice`, `ipadosDevice`, `tvosDevice`: the simulator device type to use, as listed by `xcrun simctl list devicetypes`.
  - Example: `iosDevice:iPhone-16-Pro`

Default devices:

- iOS: `iPhone-17-Pro`
- iPadOS: `iPad-Pro-13-inch-M5-12GB`
- tvOS: `Apple-TV-4K-3rd-generation-4K`

A simulator is created on the newest runtime if none exists for the device type.

> [!NOTE]
> Screenshots are only framed when `Screenshots/Tools/Frames` has a frame matching their size. Otherwise, cards use the unframed screenshot.

## Output

Screenshots are written to `Documentation/Screenshots/<Platform>/<Language>/` and shown in [Platforms](./Screenshots/platforms.md):

- `Raw`: the screenshots as captured
- `Frame`: the screenshots inside a device frame (iOS and iPadOS)
- `Card`: App Store cards with a caption over the framed screenshot

## Adding a screenshot

1. Add `screenshotHeadline<Name>` and `screenshotSubtitle<Name>` to `Translations/en.lproj/Localizable.strings`.
2. Add a case to `Screenshot`, in capture order, and return those `L10n` strings from `headline` and `subtitle`.
3. Add the case to `ScreenshotRobot.capture(_:)`: navigate with the robots and call `.screenshot(.<name>)`.
