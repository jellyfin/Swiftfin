# Bruno tvOS — overnight verification STATUS

> Run: 2026-06-22 night. Toolchain: Xcode 26.3 (tvOS 26.2 SDK), Apple TV 4K sim.
> Outcome: **Bruno is visibly working.** Both the mock-data GUI (Track A) and the real
> live-library Home (Track B) render on the simulator, and the post-login crash is gone on
> an ad-hoc-signed build. The root-cause analysis in `OVERNIGHT_TESTING_HANDOFF.md` is confirmed.

## TL;DR — what worked

| Goal | Result |
|------|--------|
| Track A — GUI from mock data (no server/sign-in/keychain) | ✅ 3 PNGs rendered & committed (`docs/screenshots/`) |
| Track B — real end-to-end (sign in → real Home) | ✅ Real library Home rendered (headless, no UI typing) |
| Signing fix persists session across relaunch | ✅ Process **ALIVE** after relaunch; no new crash |
| Both compile gates + RNG parity + lint/format | ✅ Green after every change |

## The exact build command that produced a runnable app

```bash
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
```

`** BUILD SUCCEEDED **`. The ad-hoc identity (`-`) embeds the keychain-access-group
entitlement, so the access token written during sign-in persists across relaunch — which is
exactly what fixes the crash. (The compile gate's `CODE_SIGNING_ALLOWED=NO` is for *verifying
compilation only* and intentionally strips that entitlement; do not run from it.)

## Track A — see the GUI fast (mock data)

`Swiftfin tvOS/Views/BrunoHomeView/BrunoPreviewSupport.swift` (`#if DEBUG`) adds mock
`BaseItemDto`s, `#Preview`s for the hero / a shelf / the full Home, and a `BrunoSnapshotGallery`
shown at launch when `BRUNO_SNAPSHOT=1` (`SwiftfinApp`, DEBUG-gated, inert otherwise).
`BRUNO_SNAPSHOT_VIEW` = `home` | `hero` | `shelf` selects the surface.

```bash
./bruno-verify/snapshot.sh ~/Desktop   # installs the signed build, screenshots each surface
```

Committed PNGs: `docs/screenshots/bruno-home.png`, `bruno-hero.png`, `bruno-shelves.png`.
These render the BRUNO wordmark, accent palette (`#A1CCE0`), Oswald/Inter fonts, the seeded
hero, and shelves over the stock tvOS `PosterHStack` (with native focus). Posters fall back to
the stock placeholder glyph because mock items carry no server images — layout/focus/typography
all render. No server, no sign-in, no keychain involved.

## Track B — real end-to-end (headless, no UI typing)

The tvOS on-screen keyboard makes UI typing brittle and computer-use needs an interactive
approval that isn't available unattended, so sign-in is driven programmatically instead:
`Swiftfin tvOS/Views/BrunoHomeView/BrunoAutoSignIn.swift` (`#if DEBUG`) replicates the real
flow using the app's OWN primitives — `ConnectToServerViewModel`/`UserSignInViewModel`/
`UserSessionManager` (create the server + user `StoredValues` records, authenticate via the SDK,
write the token via the stock keychain setter, resolve the session). Gated behind
`BRUNO_AUTOSIGNIN=1`; credentials are supplied at launch via `JF_BASE`/`JF_USER_NAME`/`JF_PASS`
env vars (never compiled in; sourced from the gitignored `bruno_jellyfin.env`).

```bash
./bruno-verify/e2e.sh ~/Desktop
```

Observed:
```
BRUNO_AUTOSIGNIN: SIGNED IN userID=430fc3c982b34ac5829754cf8305f797 tokenLen=32 ...
process: ALIVE after sign-in
process: ALIVE after relaunch — KEYCHAIN PERSISTED
```
The real Home rendered the live library (Godfather spotlight 1972 · Drama · ★8.7, real
Continue Watching art) and was **identical after a clean relaunch** — proving session
persistence on the signed build. Screenshots (`bruno-real-home.png`,
`bruno-real-home-relaunch.png`) were delivered out-of-band and intentionally **not committed**
(they contain personal library content; the repo has a GitHub remote).

## Crash frames seen

No NEW crash was produced by any run tonight (signed build stays alive). The newest pre-existing
report (`~/Library/Logs/DiagnosticReports/Swiftfin tvOS-2026-06-22-231043.ips`, 23:10, from
before this session's signed runs) is the documented stock keychain assertion — **zero Bruno
frames**:
```
libswiftCore   assertionFailure(_:file:line:)
Swiftfin tvOS  SwiftfinStore.State.User.accessToken.getter   ← "access token missing in keychain"
Swiftfin tvOS  UserSession.init(server:user:)
Swiftfin tvOS  static UserSessionManager.resolveCurrentSession()
Swiftfin tvOS  UserSessionManager.init()
```
Per the handoff decision rule, stock frames ⇒ signing/env issue, not a Bruno bug. The fix
(ad-hoc signing) eliminates it: see the surviving relaunch above.

## Guardrails honored

Additive only. New files live in `Swiftfin tvOS/Views/BrunoHomeView/` (tvOS-only,
file-system-synchronized group → no pbxproj edits). The only non-Bruno edits are DEBUG-gated,
inert-by-default branches in `Swiftfin tvOS/App/SwiftfinApp.swift` (a tvOS-target file — not a
shared file, not player/nav/detail). No Bruno engine source touched. swiftformat + swiftlint
clean; `./bruno-verify/run.sh` green; both compile gates green. Secrets stayed in the gitignored
env; no tokens/passwords committed (the headless helper only reads `JF_*` env at runtime).

## Reproduce from scratch

```bash
# 1. signed build (runnable app)
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
xcrun simctl boot "Apple TV 4K (3rd generation)" 2>/dev/null; open -a Simulator
# 2. mock GUI screenshots
./bruno-verify/snapshot.sh ~/Desktop
# 3. real library Home + relaunch persistence (creds from bruno_jellyfin.env)
./bruno-verify/e2e.sh ~/Desktop
```
