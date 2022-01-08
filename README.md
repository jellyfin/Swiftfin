<p align="center">
      <img alt="Swiftfin" height="125" src="https://github.com/jellyfin/SwiftFin/raw/main/Swiftfin/Assets.xcassets/AppIcon.appiconset/152.png">
  <h2 align="center">Swiftfin</h2>
  <a href="https://translate.jellyfin.org/engage/swiftfin/">
    <img src="https://translate.jellyfin.org/widgets/swiftfin/-/svg-badge.svg"/>
  </a>
  <a href="https://matrix.to/#/+jellyfin:matrix.org">
    <img src="https://img.shields.io/matrix/jellyfin:matrix.org">
  </a>
  <a href="https://sonarcloud.io/dashboard?id=jellyfin_SwiftFin">
    <img src="https://sonarcloud.io/api/project_badges/measure?project=jellyfin_SwiftFin&metric=alert_status">
  </a>
  <a href="https://discord.gg/zHBxVSXdBV">
    <img src="https://img.shields.io/badge/Talk%20on-Discord-brightgreen">
  </a>
</p>
<p align="center">
  <b>Swiftfin</b> is a modern client for the <a href="https://github.com/jellyfin/jellyfin">Jellyfin</a> media server. Redesigned in Swift to maximize direct play with the power of <b>VLC</b> and look <b>native</b> on all classes of Apple devices.
</p>

## ⚡️ Links!

<a href='https://testflight.apple.com/join/WiN0G62Q'><img height='70' alt='Join the Beta on TestFlight' src='https://anotherlens.app/testflight-badge.png'/></a>

**Don't see SwiftFin in your language?**

Check out our [Weblate instance](https://translate.jellyfin.org/projects/swiftfin/) to help translate Swiftfin and other projects.

<a href="https://translate.jellyfin.org/engage/swiftfin/">
<img src="https://translate.jellyfin.org/widgets/swiftfin/-/multi-auto.svg"/>
</a>

## ⚙️ Development

Thank you for your interest in Swiftfin, please check out the [Contribution Guidelines](https://github.com/jellyfin/SwiftFin/contributing.md).

## Intended Behaviors Due to Technical Limitations

The following behaviors are intended due to technical limitations:

- Pausing playback when app is backgrounded
  - Due to VLCKit pausing video output at the same moment

- Audio delay after un-pausing
  - Due to VLCKit, may be fixed in VLCKit v4

- No aspect fill
  - VLCKit doesn't have the ability to aspect fill the view that the video output occupies
