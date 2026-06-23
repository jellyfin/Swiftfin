# Handoff — view Bruno Home on the tvOS Simulator

> The native build is complete and merged (`bruno` → `main`, PR #1), green on Xcode 26.3
> (tvOS + iOS), RNG + determinism verified. The remaining items below are **host/Simulator
> artifacts, not Bruno code** — do **not** modify Bruno source to "fix" them.

## 1. Text input into the "Connect to server" URL field — ✅ SOLVED
Not a hardware-keyboard problem. The tvOS **on-screen keyboard drops characters when fed a
whole string at once** (automation `type` overruns its input rate, so all but ~1 char are
lost). Fix: focus the field → Select/Return to enter edit mode → **type one character at a
time / slowly**. Single discrete key presses land reliably. No I/O-menu toggle or source
change needed.

## 2. Crash on relaunch after sign-in — ⚠️ environment/signing artifact
Once a session is persisted, the app **traps on every subsequent launch** (looks like "animates
then nothing" from the tvOS app switcher).

- **Crash site:** `assertionFailure("access token missing in keychain")` —
  `Shared/SwiftfinStore/SwiftinStore+UserState.swift:33`, reached from `UserSession.init`
  (`UserSession.swift:34`) via `UserSessionManager.resolveCurrentSession()` at
  `SwiftfinApp.configure()` launch.
- **Why:** the sim build is compiled with `CODE_SIGNING_ALLOWED=NO` (our compile gate), which
  strips the keychain-access-group entitlement. Keychain writes work *within* a running process
  but **don't persist across relaunch**. After sign-in, `Defaults[.lastSignedInUserID]` + the
  user/server records persist but the keychain access-token is gone next launch → the stock
  upstream `assertionFailure` traps (Debug build).
- **Not a Bruno bug:** a properly signed device build persists the token; a Release build returns
  `""` instead of trapping. Out of the original (compile-green) scope.

### `CODE_SIGNING_ALLOWED=NO` is for the COMPILE GATE only
That flag is correct for *verifying the build compiles* (no team needed). To *run a usable app
on the sim across relaunches*, build with signing so entitlements are embedded (below).

## 3. Two ways to actually view the Home
**Quick (no rebuild) — screenshot in the first session, don't relaunch:**
```bash
DEV=$(xcrun simctl list devices tvOS available | grep -m1 -oE '[0-9A-F-]{36}')
xcrun simctl terminate "$DEV" com.diplomacymusic.bruno 2>/dev/null
xcrun simctl uninstall "$DEV" com.diplomacymusic.bruno          # clear the crash-looping stale session
APP="$(find ~/Library/Developer/Xcode/DerivedData/Swiftfin-*/Build/Products/Debug-appletvsimulator -maxdepth 1 -name '*.app' | head -1)"
xcrun simctl install "$DEV" "$APP"; xcrun simctl launch "$DEV" com.diplomacymusic.bruno
# sign in (type slowly, per §1), reach Home, then DON'T press TV/Home or relaunch:
xcrun simctl io "$DEV" screenshot ~/Desktop/bruno-home.png
```

**Durable (survives relaunch) — rebuild the tvOS scheme WITH simulator ad-hoc signing**
(build-config only, no Bruno source edits): omit `CODE_SIGNING_ALLOWED=NO` and let the sim
ad-hoc-sign so the keychain-access-group entitlement is present and the token persists, e.g.
`CODE_SIGN_IDENTITY="-"` for the simulator destination.

## Credentials
In the gitignored `bruno_jellyfin.env` at the **main checkout** repo root
(`/Users/danielbrunelle/Documents/Claude/Projects/bruno/bruno_jellyfin.env`) —
`JF_USER_NAME` / `JF_PASS`, server `http://192.168.50.19:8899`. Never commit them. Note: the
env file lives only in the main checkout, not in any git worktree.

## Already verified
App runs, rebrand applied (accent `#A1CCE0`, Oswald/Inter). Every Bruno shelf query validated
against the live API (635 movies, 19 series, 7 favorited group BoxSets, 23 genres) — see
`BRUNO_NOTES.md`. The Home renders via the stock tvOS `PosterHStack`, so it populates once
signed in (confirmed: the Home rendered in the first in-session sign-in).
