# Overnight verification loop log — 2026-06-22 night

Append-only record of each build/install/launch/check iteration.

| # | Action | Result |
|---|--------|--------|
| 1 | Signed build (ad-hoc) — baseline, no harness | ✅ BUILD SUCCEEDED |
| 2 | Add `BrunoPreviewSupport.swift` + SwiftfinApp DEBUG hook; signed build | ❌ BUILD FAILED — `init(shelf:)` main-actor isolation |
| 3 | Mark `BrunoMock.shelf` `@MainActor`; signed build | ✅ BUILD SUCCEEDED |
| 4 | `snapshot.sh` → install + launch `BRUNO_SNAPSHOT` (home/hero/shelf) | ✅ 3 PNGs; GUI renders from mock data, no crash |
| 5 | Add `BrunoAutoSignIn.swift` + SwiftfinApp `.task`; signed build | ✅ BUILD SUCCEEDED |
| 6 | `e2e.sh` → fresh install + `BRUNO_AUTOSIGNIN` launch | ✅ SIGNED IN (real 32-char token); process ALIVE; real Home rendered |
| 7 | Relaunch (no auto-sign-in) — persistence check | ✅ process ALIVE — keychain PERSISTED; Home identical |
| 8 | Crash check (`launchctl` + newest `.ips`) | ✅ no new crash; newest `.ips` is the pre-existing 23:10 stock-keychain report |
| 9 | tvOS compile gate (`CODE_SIGNING_ALLOWED=NO`) | ✅ BUILD SUCCEEDED |
| 10 | iOS compile gate | ✅ BUILD SUCCEEDED (1st attempt; a later parallel re-run hit a shared-DerivedData `build.db` lock — environment, not code — re-run alone passed) |
| 11 | `./bruno-verify/run.sh` (RNG parity) | ✅ ALL RNG CHECKS PASSED |
| 12 | swiftformat --lint / swiftlint (Bruno files) | ✅ clean |

## Decision-rule applications
- The only crash stack observed is stock (`SwiftfinStore.State.User.accessToken.getter` →
  `assertionFailure`, via `UserSession.init` / `UserSessionManager.resolveCurrentSession`),
  **zero Bruno frames** ⇒ signing/env fix, not a Bruno code fix. Applied: build with ad-hoc
  signing. Result: crash eliminated, session persists across relaunch. No Bruno source changed.

## Artifacts
- `docs/screenshots/bruno-home.png`, `bruno-hero.png`, `bruno-shelves.png` (mock, committed)
- `~/Desktop/bruno-real-home.png`, `bruno-real-home-relaunch.png` (real library, delivered
  out-of-band, not committed — personal content)
- Harness: `bruno-verify/snapshot.sh`, `bruno-verify/e2e.sh`
