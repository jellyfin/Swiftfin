# Handoff — view Bruno Home on the tvOS Simulator

> The native build is complete and merged. The **only** open item is a tvOS *Simulator*
> text-entry quirk on this host (the focused field doesn't accept typed characters), which
> blocks signing the app into Jellyfin from a fresh install. This is a host/Simulator issue,
> **not** a Bruno code issue — do not modify Bruno source to "fix" it.

## Current state
- Branch `bruno` is **merged into `main`** (PR #1). Builds **green on Xcode 26.3** for both
  `Swiftfin tvOS` and `Swiftfin` (iOS). RNG + determinism verified (`./bruno-verify/run.sh`).
- The Bruno tvOS app installs, launches, and renders the Bruno accent + Oswald/Inter fonts on
  the booted Apple TV 4K (tvOS 18.5) simulator. Bundle id `com.diplomacymusic.bruno`.
- It sits on the **"Connect to server"** screen: the URL field focuses, but typed characters
  don't land — `I/O ▸ Keyboard ▸ Connect Hardware Keyboard` shows checked yet input doesn't
  reach the field, and toggling it doesn't help.

## Goal
Enter the server URL, connect, sign in, and reach the **Bruno Home** rendering the real
library; screenshot it.

- Server URL: `http://192.168.50.19:8899`
- Credentials: **in the gitignored `bruno_jellyfin.env`** at the repo root (`JF_USER_NAME` /
  `JF_PASS`). Never commit them. `source bruno_jellyfin.env` to load.

## Build / run the sim
```bash
# build (Xcode 26.3)
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build CODE_SIGNING_ALLOWED=NO
# boot + install + launch
DEV=$(xcrun simctl list devices tvOS available | grep -m1 -oE '[0-9A-F-]{36}')
xcrun simctl boot "$DEV"; open -a Simulator
APP=$(find ~/Library/Developer/Xcode/DerivedData/Swiftfin-*/Build/Products/Debug-appletvsimulator -maxdepth 1 -name "*.app" | head -1)
xcrun simctl install "$DEV" "$APP"
xcrun simctl launch "$DEV" com.diplomacymusic.bruno
```

## Things to try for the sim text entry
1. Click the Simulator window body once (host focus), then on the focused URL field press
   **Return to enter edit mode**, *then* type — tvOS often needs Select before it accepts keys.
2. Toggle **I/O ▸ Keyboard ▸ Toggle Software Keyboard** and drive the on-screen keyboard with
   arrow keys + Return.
3. Paste: copy the URL to the host clipboard and use the Simulator's **Edit ▸ Paste** while the
   field is focused.
4. As a fallback to skip the URL screen, check whether the `swiftfin://` URL scheme can
   pre-register the server.

## What's already verified (so you can scope the work)
- The app **runs without crashing** and the rebrand is applied (accent `#A1CCE0`, fonts).
- Every Bruno shelf's query was validated against the live Jellyfin API (635 movies, 19
  series, 7 favorited group BoxSets, 23 genres) — see `BRUNO_NOTES.md`.
- The Home renders via the stock tvOS `PosterHStack`, so once signed in it will populate.
