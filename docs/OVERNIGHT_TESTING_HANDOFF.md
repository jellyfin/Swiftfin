# Overnight autonomous testing & verification handoff — get Bruno running on the sim

> **Audience:** a fresh autonomous thread running test/verify/fix loops overnight.
> **Mission:** get the Bruno tvOS Home rendering the owner's real Jellyfin library, captured as
> a screenshot — and/or render the Bruno GUI from mock data so the owner can *see it working*.
> **Repo:** `/Users/danielbrunelle/Documents/Claude/Projects/bruno`, branch `bruno` (merged to `main`).
> Build toolchain: **Xcode 26.3** (Swift 6.2.4, tvOS/iOS 26.2 SDKs). See `BRUNO_NOTES.md` for the
> full architecture/signature verification and `docs/SIM_VIEWING_HANDOFF.md` for sim basics.

---

## 0. TL;DR

1. **The post-sign-in crash is NOT a Bruno bug.** Crash log (below) proves it's the stock upstream
   keychain assertion, caused by building with `CODE_SIGNING_ALLOWED=NO` (no keychain entitlement).
   **Fix = build the sim app WITH (ad-hoc) signing so the access token persists.** (§1)
2. **Fastest way to "just see the GUI"** (no server, no sign-in, no keychain): add SwiftUI
   **Previews with mock data** to the Bruno views and render them. Sidesteps the crash entirely. (§2)
3. **Real end-to-end:** signed build → install → sign in (type **one char at a time**) → screenshot
   the Home before relaunch. (§3) Loop design in §4.
4. **Do NOT modify Bruno source to "fix" the crash** — it's an environment/signing artifact. Bruno
   source is additive, compile-green, red-team-reviewed, and merged. Guardrails in §8.

---

## 1. The crash — ROOT CAUSE CONFIRMED (keychain, not Bruno)

Symptom the owner saw: typed login in by hand, it passed the sign-in gate, then the app crashed back
to the tvOS Home screen; also crashes on every relaunch.

**Actual crash report** (`~/Library/Logs/DiagnosticReports/Swiftfin tvOS-2026-06-22-23104*.ips`):
```
EXC_BREAKPOINT (SIGTRAP)
assertionFailure(_:_:file:line:)
SwiftfinStore.State.User.accessToken.getter      ← Shared/SwiftfinStore/SwiftinStore+UserState.swift:33
UserSession.init(server:user:)                    ← Shared/Services/UserSession/UserSession.swift:34
static UserSessionManager.resolveCurrentSession() ← Shared/Services/UserSession/UserSessionManager.swift:151
UserSessionManager.init()
closure #1 in Container.userSessionManager.getter (Factory)
```
The trapping line (`SwiftinStore+UserState.swift:30-37`):
```swift
var accessToken: String {
    get {
        guard let accessToken = Container.shared.keychainService().get("\(id)-accessToken") else {
            assertionFailure("access token missing in keychain")   // ← traps in DEBUG
            return ""
        }
        return accessToken
    }
    set { Container.shared.keychainService().set(newValue, forKey: "\(id)-accessToken") }
}
```
**Zero Bruno frames.** Why it happens: the compile gate uses `CODE_SIGNING_ALLOWED=NO`, which strips
the keychain-access-group entitlement. Without it, `keychainService().set(...)` during sign-in does
not durably store the token, so the very next `resolveCurrentSession()` (run lazily when the Factory
`Container` first resolves `userSessionManager`, i.e. immediately after sign-in and again on every
launch) reads it back as missing → the stock `assertionFailure` traps. Confirmed environment artifact.

### The fix — build the sim app WITH ad-hoc signing
The compile gate (`CODE_SIGNING_ALLOWED=NO`) is for *verifying compilation only*. To RUN a usable app,
build with signing so entitlements are embedded:
```bash
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
```
**CONFIRMED:** this exact command **BUILD SUCCEEDED** on Xcode 26.3 and wrote
`…/DerivedSources/Entitlements-Simulated.plist` + codesigned with identity `-` (ad-hoc) — i.e. the
keychain-access-group entitlement IS now embedded. (Not yet driven through sign-in end-to-end; that's
loop task #1.) (`XcodeConfig/DevelopmentTeam.xcconfig` has placeholder `DEVELOPMENT_TEAM=ABCDE12345`;
for a *simulator* ad-hoc build no real team is needed. If ad-hoc still doesn't persist the keychain, fallbacks: (a) set a
real `DEVELOPMENT_TEAM` and use automatic signing; (b) confirm the target's `*.entitlements` includes
`keychain-access-groups`; (c) as a non-crash stopgap a **Release** build returns `""` instead of
trapping — the app won't crash but the session token is still empty, so it isn't truly logged in. The
real fix is making the keychain WRITE succeed = signing.)

**First loop task:** produce a signed build, install, sign in, and confirm it no longer traps (capture
a fresh `.ips` if it does — see §6).

---

## 2. Track A — SEE THE GUI FAST via SwiftUI Previews (no server, no sign-in, no keychain)

Bruno is native tvOS SwiftUI, so it can't run in a browser — **but SwiftUI Previews render the views in
Xcode's canvas from mock data, with zero sign-in.** This is the most reliable "just see it working" path
and it completely sidesteps the keychain crash. (The design-intent reference also runs in a browser:
`prototype/design_handoff_bruno/Bruno_standalone.html` — open it to compare against.)

**Deliverable:** add DEBUG-only `#Preview` providers (additive, no behavior change) that feed mock
`BaseItemDto`s into the Bruno views:
- `BrunoHeroView(items: [mockMovie, ...])` → renders the hero (Oswald title, meta, Play/More, dots).
- A `BrunoShelfView` whose `BrunoShelfViewModel.shelf.source == .items([mockMovie, ...])` and whose
  `load()` has run → renders a shelf row via the stock `PosterHStack` (mock items show placeholder art;
  layout, fonts, focus all render).
- Best: a `BrunoHomePreviewContainer` that stacks the hero + several mock shelves in the exact
  `ScrollView { LazyVStack { … } }` from `BrunoHomeView.content` to render the **whole Home** from mock
  data (bypassing the session-bound `@StateObject`).

Mock data is trivial — `BaseItemDto` has a memberwise init (already used in
`Shared/Objects/Bruno/BrunoHomePlan+SelfCheck.swift`):
```swift
BaseItemDto(id: "m1", name: "Blade Runner", communityRating: 8.1, productionYear: 1982, type: .movie)
```
Render previews headlessly and snapshot them (e.g. drive the Xcode canvas, or use a preview-snapshot
tool / a tiny `ImageRenderer`-based DEBUG harness) so the owner gets PNGs of the Bruno GUI overnight.
Keep all of this `#if DEBUG` and in `Swiftfin tvOS/Views/BrunoHomeView/` so it never ships.

---

## 3. Track B — real end-to-end (signed build → sign in → screenshot)

```bash
DEV=$(xcrun simctl list devices tvOS available | grep -m1 -oE '[0-9A-F-]{36}')   # Apple TV 4K, tvOS 18.5
xcrun simctl boot "$DEV" 2>/dev/null; open -a Simulator
xcrun simctl terminate "$DEV" com.diplomacymusic.bruno 2>/dev/null
xcrun simctl uninstall "$DEV" com.diplomacymusic.bruno          # clear any crash-looping stale session
APP="$(find ~/Library/Developer/Xcode/DerivedData/Swiftfin-*/Build/Products/Debug-appletvsimulator -maxdepth 1 -name '*.app' | head -1)"
xcrun simctl install "$DEV" "$APP"
xcrun simctl launch "$DEV" com.diplomacymusic.bruno
```
**Sign-in mechanics (critical):** the tvOS on-screen keyboard **drops characters when fed a whole
string at once** — type **one character at a time / slowly** into the focused field. Flow: focus URL
field → Select/Return to enter edit mode → type `http://192.168.50.19:8899` slowly → Connect → choose
user `BrunelleHouse` → type the password slowly → done. The Simulator must be the frontmost app for
computer-use; `I/O ▸ Keyboard ▸ Connect Hardware Keyboard` is already on.
**Credentials:** gitignored `bruno_jellyfin.env` at the **main checkout** repo root (`JF_USER_NAME`,
`JF_PASS`, `JF_BASE`). `source` it; never commit it. (It lives only in the main checkout, not worktrees.)
Once Home is up: `xcrun simctl io "$DEV" screenshot ~/Desktop/bruno-home.png`. With a SIGNED build you
can relaunch freely; with an unsigned build, screenshot in the first session before any relaunch.

**Faster sign-in option to explore:** the access token can be minted via the API
(`POST /Users/AuthenticateByName {Username,Pw}` — verified working) — investigate pre-seeding Swiftfin's
session store (CoreStore user/server records + keychain token under key `"\(userID)-accessToken"`) so the
app starts authenticated without UI typing. This is the highest-leverage automation if it pans out.

---

## 4. Autonomous loop design

```
loop until (Home screenshot captured AND no crash on relaunch) OR budget exhausted:
  1. build signed sim app (§1). On failure → read /tmp build log, fix BUILD CONFIG only, retry.
  2. uninstall + install + launch (§3).
  3. wait; check `xcrun simctl spawn "$DEV" launchctl list | grep diplomacymusic.bruno`.
     - if process gone → CRASH. Pull newest ~/Library/Logs/DiagnosticReports/*.ips, parse (§6),
       record the top frames. If frames are stock keychain/signing → adjust signing, NOT Bruno.
       If frames are Bruno (Shared/Objects/Bruno or BrunoHomeView) → real bug, fix + re-verify (§5).
  4. if running and at sign-in screen → drive sign-in (§3, type slowly).
  5. if Home rendered → screenshot to ~/Desktop and to docs/ ; verify shelves are non-empty.
  6. relaunch once → confirm no keychain crash (validates the signing fix).
record every iteration's outcome + screenshot/crash-frame in a running log file you append to.
```
Always keep both compile gates green between code changes (§5). Prefer Track A previews first (cheap,
deterministic, no sign-in) to confirm the GUI renders, then Track B for the real-data screenshot.

---

## 5. Verification suite (run after ANY code change; must stay green)

```bash
# tvOS compile gate
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build CODE_SIGNING_ALLOWED=NO
# iOS compile gate (needs iOS 26 sim runtime; if actool errors with a stale-runtime msg, run:
#   killall -9 com.apple.CoreSimulator.CoreSimulatorService  )
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin" \
  -destination 'generic/platform=iOS Simulator' -skipMacroValidation build CODE_SIGNING_ALLOWED=NO
# RNG ↔ JS parity + determinism (pure-logic, no Xcode):
./bruno-verify/run.sh        # expect: ALL RNG CHECKS PASSED
# format + lint (Bruno files must be clean):
swiftformat --lint Shared/Objects/Bruno "Swiftfin tvOS/Views/BrunoHomeView"
swiftlint lint --quiet Shared/Objects/Bruno "Swiftfin tvOS/Views/BrunoHomeView"
```
The plan-determinism contract is also asserted at runtime in DEBUG via
`assert(BrunoHomePlan.selfCheckPassed())` in `BrunoHomeViewModel.init` — note this means if a real
Bruno determinism regression is introduced, the app WILL trap on opening Home (stack would show
`BrunoHomePlan.selfCheckPassed` / `BrunoHomeViewModel.init`, unlike tonight's stock-keychain stack).

---

## 6. Getting/parsing crash logs

```bash
ls -t ~/Library/Logs/DiagnosticReports/"Swiftfin tvOS"*.ips | head        # newest crash
# or a full sim diagnostic bundle:  xcrun simctl diagnose
python3 - "$(ls -t ~/Library/Logs/DiagnosticReports/'Swiftfin tvOS'*.ips | head -1)" <<'PY'
import sys,json
raw=open(sys.argv[1]).read(); p=json.loads(raw[raw.index('\n')+1:])
print("exc:",p.get("exception"),"term:",p.get("termination",{}).get("indicator"))
imgs=p.get("usedImages",[])
for t in p.get("threads",[]):
    if t.get("triggered"):
        for f in t["frames"][:14]:
            i=f.get("imageIndex"); n=imgs[i]["name"] if i is not None and i<len(imgs) else "?"
            print(f'  {n} +{f.get("imageOffset")} {f.get("symbol","")}')
PY
```
**Decision rule:** stock frames (`SwiftfinStore`, `UserSession`, `Keychain`, `Factory`) ⇒ signing/env
issue — fix the build, not the code. Frames in `…/Bruno/…` or `…/BrunoHomeView/…` ⇒ genuine Bruno bug.

---

## 7. Architecture & code reference map

**Engine contract:** `NATIVE_FORK_PLAN.md` (§C verified architecture, §D determinism, §E shelves);
`prototype/design_handoff_bruno/PRODUCT_SPEC.md` (shelf taxonomy §3, engine §4, API map §6);
`prototype/design_handoff_bruno/Bruno.dc.html` (the JS this ports: `rng` L453, `exploreGen` L490,
`buildBase` L503, `reshuffle` L548). Verified signatures live in `BRUNO_NOTES.md`.

**Pure logic — `Shared/Objects/Bruno/` (compiles on iOS+tvOS):**
- `BrunoRNG.swift` — `mulberry32` port (UInt32 `&+`/`&*`), `shuffled`/`pick`/`subSeed`. JS-bit-exact
  (verified by `bruno-verify/`). Don't touch the wrapping ops.
- `BrunoQuery.swift` — pure `GetItems` descriptor; stable server sort + client `shuffleSeed` (never
  `sortBy=.random`). Note `JellyfinAPI.SortOrder`/`JellyfinAPI.ItemFilter` are qualified (name clashes).
- `BrunoShelf.swift` — row descriptor: `Kind` (per-role, for adjacency dedupe) + `dedupeKey`
  (per-content, for cross-page dedupe) + `Source {resume,nextUp,recentlyAdded,query,items}`.
- `BrunoQueryLibrary.swift` — `BaseItemKindLibrary` mapping `BrunoQuery`→`GetItemsParameters`, applies
  the seeded shuffle. Same shape as `Shared/Objects/Libraries/RecentlyAddedLibrary.swift`.
- `BrunoLibrarySnapshot.swift` — one async fetch of the 7 favorited group BoxSets + children + genres +
  years (no hardcoded IDs). `load(client:userID:)`.
- `BrunoHomePlan.swift` — `build(seed:snapshot:now:)` PURE over (seed, snapshot, now); the spine +
  10 explore generators; `appendExplore(...)` +2/page; `dedupedAndCapped` (adjacent-kind + content +
  <3 drop + cap 18). `now` is injected (no wall-clock).
- `BrunoHomePlan+SelfCheck.swift` (`#if DEBUG`) — `selfCheckPassed()` determinism invariant.

**tvOS UI — `Swiftfin tvOS/Views/BrunoHomeView/` (tvOS target only):**
- `BrunoHomeViewModel.swift` — hand-written `Stateful` (NOT the `@Stateful` macro). `refresh`/`shuffle`/
  `appendExplore`; loads snapshot→plan→child VMs (`await child.refresh()`); hero superset; seed is
  day-stable in `Defaults` (`.brunoSeed`/`.brunoSeedDay`). DEBUG determinism `assert` in `init` (L67).
- `BrunoShelfViewModel.swift` — type-erases child paging VMs via the non-generic `BrunoPagingElements`
  existential (avoids a swiftformat generic-rewrite). `shouldDisplay` gates empty/<3 rows.
- `BrunoHomeView.swift` — `@StateObject` VM; `ScrollView{LazyVStack{ header; BrunoHeroView; ForEach
  shelves; sentinel→appendExplore }}`; Shuffle button; reduced-motion guard.
- `BrunoHeroView.swift` — seeded 5-item spotlight; Play/More → `router.route(to:.item(item:))`.
- `BrunoShelfView.swift` — accent eyebrow + Oswald title over the stock tvOS `PosterHStack` (native
  focus, card→stock detail→Play).

**Integration (the only shared-file edit):** `Shared/Coordinators/Tabs/TabItem.swift` `home` →
`#if os(tvOS) BrunoHomeView() #else HomeView() #endif`. Rebrand: `Shared/Extensions/Color.swift`
(`Color.bruno.*`), `Shared/Services/SwiftfinDefaults.swift` (accent defaults + seed keys),
`Shared/Extensions/Font+Bruno.swift`, `Shared/App/SwiftfinApp+ValueObservation.swift` (app-level accent),
fonts in `Swiftfin tvOS/Resources/Fonts/` + `UIAppFonts` in `Swiftfin tvOS/Resources/Info.plist`.

---

## 8. Guardrails (do NOT violate)

- **Don't "fix" the keychain `assertionFailure` in source** — it's stock upstream; the fix is signing.
- **Additive only.** Do not modify the player, navigation, or detail screens. The only shared-file edit
  is the `#if os(tvOS)` `TabItem.home` swap. Keep new files in `Shared/Objects/Bruno/` or
  `Swiftfin tvOS/Views/BrunoHomeView/` (file-system-synchronized groups → auto-included; no pbxproj edits).
- **Both compile gates must stay green** after every change (§5). Format + lint clean.
- **Secrets:** creds only in gitignored `bruno_jellyfin.env`. Never commit tokens/passwords; scan diffs.
- **Toolchain:** we're on Xcode 26.3 with the fork restored to its authored state (Nuke 13.0.2, Pulse
  5.2.0, Liquid Glass, isolated conformance). Don't reintroduce the 16.4 compat downgrades.
- Don't hardcode a sim device name (`generic/platform=…`); don't `sortBy=.random` on stable shelves.

---

## 9. Already verified (so you can scope)

- Both schemes BUILD SUCCEEDED on Xcode 26.3. RNG JS-bit-exact; determinism 300k-seed clean +
  red-team-reviewed (`BRUNO_NOTES.md`, prior review).
- App launches, rebrand applied (accent `#A1CCE0`, Oswald/Inter) — verified by screenshot.
- The Bruno **Home rendered** in the first in-session sign-in before the keychain crash (owner saw it),
  i.e. the feature works; the blocker is purely session persistence on the unsigned build.
- Live library validated: 635 movies, 19 series, 7 favorited group BoxSets (New Releases/Directors/
  Decades/Genres/Studios/Curated/Seasonal), 23 genres, resume=14, nextUp=5 (`BRUNO_NOTES.md §Live`).

**Definition of done for the night:** a screenshot of the Bruno Home rendering the real library from a
signed build that survives relaunch — and/or mock-data preview PNGs of the hero + shelves. Append every
loop's result to a log; leave a short STATUS.md summarizing what worked, what crashed (with frames), and
the exact build command that produced a runnable app.
