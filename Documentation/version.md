# Swiftfin Minimum Supported OS Policy

Determining the minimum supported OS is a deliberate decision that balances keeping up with new developments and maintaining compatibility with older devices. Some applications are simple enough to continue supporting older OS versions, but for projects like Swiftfin, doing so comes with trade-offs:

- Maintaining a low minimum OS while adding new features requires constant version checks.
- Portions of code often need to be segregated for old vs. new OS support.
- This approach is error-prone and can become intrusive over time.

## SwiftUI Considerations

Swiftfin is built using **SwiftUI**, Apple’s primary UI framework. While the early years of SwiftUI had limitations, the framework has matured significantly:

- Annual updates bring conveniences that simplify feature development.
- Some improvements are foundational, while others are for developer convenience.
- As SwiftUI stabilizes, fewer improvements each year are considered essential, which can widen the window for minimum supported OS versions.

## Development Philosophy

Jellyfin caters to a “hacker” audience, and older devices are often perfectly suited for personal media consumption. However, Swiftfin must prioritize modern development practices:

- **No consideration** will be given for OS versions that allow jailbreaking or reflect personal dislike of newer versions.
- While other Jellyfin clients may support older OS versions, they are **not built with SwiftUI**, which introduces additional constraints.

## OS Support Timeline

Decisions to drop OS versions will aim to be communicated **months in advance**. Work targeting the latest Swiftfin version for a given OS may also delay these changes.

Older OS versions may still receive **limited support**:

- Only small bug fixes will be applied on separate branches.
- **New features and backports will not be accepted**, even if minor.

## Questions, Comments, or Concerns

Our discussion for this topic can be found at [Supported OS Versions](https://github.com/jellyfin/Swiftfin/discussions/1564).
