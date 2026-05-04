# SwiftfinTests / SwiftfinTVOSTests

Unit tests for Swiftfin. Two bundles, hosted on their respective apps:

- `SwiftfinTests` — hosted on `Swiftfin iOS`. Covers shared, pure-logic code
  imported via `@testable import Swiftfin`.
- `SwiftfinTVOSTests` — hosted on `Swiftfin tvOS`. Reserved for tvOS-specific
  behavior (player overlay, focus engine, click-only remote handling).

## Running

From Xcode, select the matching scheme (`Swiftfin` or `Swiftfin tvOS`) and
hit `⌘U`.

From the command line:

```sh
xcodebuild test \
  -project Swiftfin.xcodeproj \
  -scheme "Swiftfin" \
  -destination "platform=iOS Simulator,name=iPhone 17"

xcodebuild test \
  -project Swiftfin.xcodeproj \
  -scheme "Swiftfin tvOS" \
  -destination "platform=tvOS Simulator,name=Apple TV"
```

## Adding tests

Drop `*.swift` files into `Tests/SwiftfinTests/` (iOS) or
`Tests/SwiftfinTVOSTests/` (tvOS) and run `ruby Scripts/add_test_target.rb`
to pick up new files into the matching target's source build phase. The
script is idempotent.

Tests use `@testable import Swiftfin_iOS` (or `@testable import Swiftfin_tvOS`).
The module names are derived from `PRODUCT_MODULE_NAME` which Xcode
produces from `PRODUCT_NAME = $(TARGET_NAME)`. Prefer `internal` access
on symbols you want covered.
