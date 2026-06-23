# Bruno (Native tvOS) — One-Shot Execution Plan · Swiftfin fork

> **You are a fresh autonomous coding thread.** This repo **is already the Swiftfin fork**, set up at
> `REPO` (below) on branch **`bruno`**. Transform its tvOS Home into the **Bruno** streamer experience,
> rebranded, wired to the owner's real Jellyfin library — producing a **compiling, runnable prototype in
> one shot**. You do **not** deploy to hardware (the owner does). You **do** write all code and keep the
> project **compiling** (the §LOCKED compile gate after every task).
>
> **Read before coding:** design is law — `prototype/design_handoff_bruno/PRODUCT_SPEC.md` (shelf
> taxonomy §3, dynamic engine §4, API map §6) and `prototype/design_handoff_bruno/README.md` (visual
> system/tokens). View the intent in `prototype/design_handoff_bruno/Bruno_standalone.html`. Port the
> engine logic from `prototype/design_handoff_bruno/Bruno.dc.html` (`rng` L453, `epsFor` L470,
> `exploreGen` L490, `buildBase` L503, `reshuffle` L548, `detailVM` L585).
>
> **This plan was red-teamed against the real Swiftfin source.** §C ("Verified architecture") is fact,
> not guess — but signatures still drift between Swiftfin releases, so **T0 re-verifies them** and
> `BRUNO_NOTES.md` becomes the source of truth if anything differs.

---

## ⚿ LOCKED — paths & dev process (do NOT deviate)

| Name | Value |
|---|---|
| **REPO** (the fork; where ALL work happens) | `/Users/danielbrunelle/Documents/Claude/Projects/bruno` |
| **origin** | `DiplomacyMusic/swiftfin-bruno` (the fork) |
| **upstream** | `jellyfin/Swiftfin` (for rebasing) |
| **Branch** | `bruno` (already checked out) |
| **Worktrees** (if you parallelize) | `/Users/danielbrunelle/Documents/Claude/Projects/bruno-worktrees/<name>` — `git -C REPO worktree add ../bruno-worktrees/<name> <branch>` |
| **Build contract** | `REPO/NATIVE_FORK_PLAN.md` (this file) |
| **Design source of truth** | `REPO/prototype/design_handoff_bruno/` |
| **prototype/** | the old web demo + design bundle — **REFERENCE ONLY, no dev there** |

Rules (every task obeys):
- Work **only** inside REPO (and worktrees under `bruno-worktrees/`). **Never** create files in `$HOME` or outside these paths. **Never** clone anything into `$HOME`/`$PWD`.
- Branch **`bruno`**; commit per task; push the branch; open **one** PR on origin at the end. Never touch `main`.
- **Dependencies (verified):** **Carthage = VLCKit only** (`Cartfile` has just MobileVLCKit + TVVLCKit). **JellyfinAPI + StatefulMacro resolve via Swift Package Manager**, not Carthage. So, once:
  ```bash
  cd "/Users/danielbrunelle/Documents/Claude/Projects/bruno"
  brew bundle --file Brewfile                 # carthage, swiftformat, swiftgen, swiftlint
  carthage update --use-xcframeworks          # VLCKit binaries only
  xcodebuild -resolvePackageDependencies -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS"   # SPM (needs GitHub network)
  xcodebuild -downloadPlatform tvOS           # install a tvOS simulator runtime (NONE is preinstalled)
  ```
  Create `XcodeConfig/DevelopmentTeam.xcconfig` with a placeholder `DEVELOPMENT_TEAM` and a unique `PRODUCT_BUNDLE_IDENTIFIER`.
- **Compile gate after EVERY task** — a task is not done until BOTH are green (no device, no booted sim needed):
  ```bash
  xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
    -destination 'generic/platform=tvOS Simulator' build CODE_SIGNING_ALLOWED=NO
  ```
  (Use `generic/platform=tvOS Simulator` — do NOT hardcode a device name; the named device may not exist. Discover real devices with `xcrun simctl list devices tvOS` only if you must boot one.)
- **Do NOT deploy to hardware** (owner's step). **Do NOT modify** the player, navigation, or detail screens. Edits are **additive**; **keep the iOS target compiling** (gate it in T9).
- **Secrets:** Jellyfin creds live only in REPO-local gitignored config / `BRUNO_NOTES.md` — **never committed**.

---

## C. Verified architecture (checked against the real source — trust, but re-verify in T0)

### C1. A Home shelf = 3 parts
1. **`Library` struct** conforming `BaseItemKindLibrary` (a `PagingLibrary` of `BaseItemDto`). Implement
   `retrievePage(...)`. Copy a real example: `Shared/Objects/Libraries/{RecentlyAddedLibrary,NextUpLibrary,ResumeItemsLibrary,ItemLibrary}.swift`.
2. **`PagingLibraryViewModel(library:)`** wraps it. **Refresh with `await vm.refresh()`; page with `vm.getNextPage()`** — these are **`@Stateful`-macro-generated direct methods, NOT `.send(...)`**. Items are
   **`vm.elements: IdentifiedArrayOf<BaseItemDto>`** (an `IdentifiedArray`, not a plain array — `PosterHStack` accepts it; see `LatestInLibraryView.swift:31`).
3. **A tvOS section view** rendering `PosterHStack(title:type:items:) { item in router.route(to: .item(item: item)) }`.
   Template: `Swiftfin tvOS/Views/HomeView/Components/LatestInLibraryView.swift` (note it **guards `viewModel.elements.isNotEmpty`**).
   ⚠️ The **tvOS** `PosterHStack` action is single-arg `(Element) -> Void`; the **iOS** one is `(Element, Namespace.ID) -> Void`. Keep `BrunoHomeView`/`BrunoShelfView` in `Swiftfin tvOS/` ONLY.

### C2. Data layer (JellyfinAPI SDK, Get-based)
```swift
var p = Paths.GetItemsParameters()
p.userID = userSession.user.id
p.enableUserData = true
p.fields = .MinimumFields          // verify; add .mediaSources/.overview/.people as needed
p.isRecursive = true
p.limit = pageSize; p.startIndex = pageOffset
p.includeItemTypes = [.movie]      // or [.movie,.series] / [.boxSet]
p.genres = ["Action"]              // genre NAMES (verified)
p.studioIDs = ["<id>"]; p.personIDs = ["<id>"]; p.years = [1999]; p.parentID = "<boxSetId>"
p.filters = [.isFavorite]          // [ItemFilter] — VERIFY the .isFavorite case in T0
p.sortBy = [.sortName]; p.sortOrder = [.ascending]   // see Determinism — avoid .random for reproducible shelves
let items = try await userSession.client.send(Paths.getItems(parameters: p)).value.items ?? []
```
⚠️ **`minCommunityRating` is used NOWHERE in Swiftfin** and is unverified in the SDK. **T0 must confirm the exact property name.** If absent/renamed: fetch with a stable sort and **filter client-side on `item.communityRating`**, or use `sortBy=[.communityRating], sortOrder=[.descending]` + take N. Do not let Hero/acclaimed shelves depend on an unconfirmed field.
Special endpoints: `Paths.getResumeItems`, `Paths.getNextUp`, `Paths.getPersons`, `Paths.getGenres`. Counts/thresholds: `enableTotalRecordCount = true` → `.value.totalRecordCount`.

### C3. State machine — use the HAND-WRITTEN `Stateful`, not the macro
`HomeViewModel` uses the hand-written `Stateful` protocol: `enum Action: Equatable`, `enum State`,
`func respond(to action: Action) -> State`, dispatched via `viewModel.send(.refresh)` (protocol extension
in `Shared/Objects/Stateful.swift`). The **`@Stateful` MACRO is a different thing** (external SPM
`StatefulMacro`, used by `PagingLibraryViewModel`) that generates direct methods and has **no `respond`/`send`**.
➜ `BrunoHomeViewModel` copies the **hand-written** shape (Action/State/`respond(to:)`/`send`). Do **NOT** apply
`@Stateful` to it. Refresh child paging VMs with `await child.refresh()` (their macro method), never `.send`.

### C4. Navigation, images, detail, player
- `@Router private var router` → `router.route(to: .item(item: someBaseItemDto))` opens stock detail
  (Movie/Series/**Collection** all handled). Tapping a group BoxSet → its native collection grid (free).
- `TabItem.home` is in `Shared/Coordinators/Tabs/TabItem.swift` and is **shared by iOS + tvOS**. Swap it
  **inside `#if os(tvOS)`** so iOS keeps stock `HomeView()` and stays compiling.
- Images: `item.imageSource(.backdrop, maxWidth:)` / `.primary` / `.logo`; person:
  `BaseItemPerson.portraitImageSources(maxWidth:)`. `PosterHStack` fetches per `type` — prefer `.landscape` (backdrop) for Bruno's look (verify `PosterDisplayType` case names in T0).
- **Player & detail are complete — do not modify.** Hero "Play" for the proto = `router.route(to: .item(item:))`
  (detail screen). Direct hero-play (build `MediaPlayerItemProvider` → `.videoPlayer`) = **TODO, not in the one-shot**.
- Stock Home loads `resumeItems` into `OrderedSet<BaseItemDto>` directly; `ResumeItemsLibrary`/`NextUpLibrary`
  exist and can back a `PagingLibraryViewModel` — Bruno uses them that way (a deliberate divergence; fine).

---

## D. Determinism contract (corrected — this is subtle, get it right)
- `BrunoHomePlan.build(seed, snapshot)` is **PURE over SHELF DESCRIPTORS** (kind/title/lens/query/order/posterType) — **not** over fetched items. The JS prototype is pure only because it runs over a hardcoded array; our contents come from async, paged, server-ordered queries.
- For a shelf to be reproducible, its query MUST use a **stable server sort** (`.sortName`/`.premiereDate`) and then a **client-side seeded shuffle** (`BrunoRNG.shuffled(_:seed:)`). **NEVER `sortBy=[.random]`** for shelves meant to be stable (the server reshuffles every call).
- Hero / "Acclaimed": fetch a **stable superset** (e.g. high-rated via `.communityRating` desc, or all ≥ threshold via stable sort) then seed-shuffle client-side and take N.
- `reshuffle()`: the **new seed is random** (`UInt32.random`); `build(from: newSeed)` is then pure. (That's the intended "surprise me.")
- **`mulberry32` in Swift:** `UInt32` throughout, **wrapping ops everywhere** — `&+`, `&*` (JS `Math.imul`/`>>>0` = 32-bit wraparound; plain `+`/`*` will TRAP). Includes seed-derivation: `seed &* 97 &+ i &* 13`, `seed &* 131 &+ ...`. Shifts `>>` are logical on `UInt32`. Final: `Double(r) / 4_294_967_296`. **Add a unit test** asserting the Swift sequence equals a captured JS `mulberry32` sequence for a fixed seed.
- Port note: the JS `year` generator double-draws (computes `y`, then ignores it). **Intended behavior:** pick a seeded `productionYear` present in the snapshot, query `years = [y-2 … y+2]` (expand the window), then seed-shuffle. Fix the quirk; don't reproduce it.

---

## E. Library snapshot + per-shelf source of truth
`BrunoLibrarySnapshot` (fetched once, async, then the plan is pure over it):
- `favoriteGroupBoxSets`: `includeItemTypes=[.boxSet]`, `filters=[.isFavorite]`.
- `childrenByGroupName`: for each group whose `name` ∈ {Directors, Decades, Studios, Genres, Curated, Seasonal}, its children via `parentID`.
- `genres` (`getGenres`), `years` (distinct `productionYear` from a movies query, or derived).

Each shelf has ONE source of truth + a fallback + an empty-drop rule (drop if `< MIN_ITEMS`, e.g. 3 — mirror `LatestInLibraryView`'s `isNotEmpty` guard):

| Shelf | Primary source | Fallback |
|---|---|---|
| Browse the Collection | `favoriteGroupBoxSets` (tile/portrait art) | — (drop if empty) |
| Browse by Director | children of **Directors** group BoxSet (`parentID`, portrait) | `getPersons(personTypes:[.director])` ranked by item count |
| Eras / Decades | children of **Decades** group | `years` buckets via `years=` |
| {Studio}/{Genre}/{Curated}/Seasonal lens | seeded child of that group | computed query (`studioIDs`/`genres`/`years`) |
| Spotlight on {director} | seeded child of Directors group → its children (films) | `personIDs=[seededDirectorId]` |
| Acclaimed/Hero/year/critics (explore) | computed `getItems` (stable sort + seeded shuffle) | — |

Thresholds (≥2/≥3 films): compute from snapshot child counts or `totalRecordCount` — never assume. If a group BoxSet is absent, use the fallback; if that still yields `< MIN_ITEMS`, **drop the shelf**.

---

## F. Tasks (each ends GREEN on the §LOCKED tvOS compile gate)

**T0 — Preflight, baseline-green, verify.** (No fork/clone — REPO is already the fork on branch `bruno`.)
Run the §LOCKED deps block (`brew bundle`, `carthage update`, `-resolvePackageDependencies`, `-downloadPlatform tvOS`); create `DevelopmentTeam.xcconfig`. Get the **unmodified** `Swiftfin tvOS` scheme to a **green compile gate**. Then write `REPO/BRUNO_NOTES.md` verifying these exact local signatures (resolve SPM first, then inspect the checked-out `jellyfin-sdk-swift` under DerivedData/SourcePackages):
`Paths.GetItemsParameters` field names **incl. whether `minCommunityRating` exists**; `ItemFilter.isFavorite`; `ItemSortBy` cases; `PosterDisplayType` cases; tvOS `PosterHStack` init; `PagingLibraryViewModel.elements` type + `refresh()`/`getNextPage()`; hand-written `Stateful` vs `@Stateful` macro; `@Router`/`.item(item:)`; `TabItem.home` location; `imageSource` API; the installed tvOS sim device name. **Accept:** stock tvOS builds green; `BRUNO_NOTES.md` complete (it overrides this plan on any drift).

**T1 — Rebrand.** Brand colors in `Color.swift` (`Color(hex:)`); set **both** `accentColor` **and** `userAccentColor` defaults in `SwiftfinDefaults.swift` to `#A1CCE0` (or theme-level). Fonts: ship Oswald+Inter `.ttf` **locally** (do NOT depend on a network fetch; if unavailable, fall back to system fonts + TODO); add to `Swiftfin tvOS/Resources/` AND the tvOS target's **Copy Bundle Resources**; **CREATE** the `UIAppFonts` array in `Swiftfin tvOS/Resources/Info.plist` (it doesn't exist); **ADD** `CFBundleDisplayName = Bruno` (only `CFBundleName` exists); add `Font` helpers in `Font.swift`. **Accept:** build green; accent + fonts applied.

**T2 — Data + RNG foundation** in `Shared/Objects/Bruno/`: `BrunoRNG.swift` (mulberry32 per §D + `shuffled`/`pick` + **unit test** vs captured JS sequence); `BrunoShelf.swift` (descriptor incl. `posterType: PosterDisplayType`); `BrunoQuery.swift`; `BrunoQueryLibrary.swift` (`BaseItemKindLibrary`; maps `BrunoQuery`→`GetItemsParameters` using ONLY verified fields; `minCommunityRating` via fallback if unverified). **Accept:** build green; debug fetch returns real items (e.g. favorite BoxSets).

**T3 — Snapshot + seeded plan** (`Shared/Objects/Bruno/`): `BrunoLibrarySnapshot.swift` (§E async fetch); `BrunoHomePlan.swift` — `static func build(seed:snapshot:) -> [BrunoShelf]`, **pure over descriptors** (§D), generators per §E (stable sort + client seeded shuffle, **never `.random`**), dedupe (no adjacent same-kind; cap ~18), seasonal date window, `appendExplore(into:seed:page:)`. **Accept:** build green; unit test: `build(seed)` stable across calls, varies by seed, no adjacent dup kinds, empty groups dropped.

**T4 — `BrunoHomeViewModel`** (hand-written `Stateful`, §C3): `enum Action: Equatable {refresh,backgroundRefresh,shuffle,appendExplore}`, `State`, `respond(to:)`. On `refresh`: load snapshot → `plan = build(seed,snapshot)` → instantiate a child VM per shelf (`PagingLibraryViewModel<BrunoQueryLibrary>` for `.query`; `ResumeItemsLibrary`/`NextUpLibrary`/`RecentlyAddedLibrary`-backed for stock kinds) → `await child.refresh()` each → publish `@Published var shelves`. `seed = dayStamp()` persisted in `Defaults`; `shuffle` = random reseed + rebuild + scroll-to-top; `appendExplore` lives **on this VM** (not on a paging VM). **Accept:** build green; shelves populate live.

**T5 — `BrunoHomeView`** (tvOS-only, §C1/§C4) + integration: `switch viewModel.state`; content = `ScrollView { LazyVStack { BrunoHeroView(...) ; ForEach(viewModel.shelves) { BrunoShelfView($0) } } }`. `BrunoShelfView` → `PosterHStack(title:type:items: childVM.elements) { item in router.route(to: .item(item: item)) }`, guarded `isNotEmpty`. Shuffle button; bottom sentinel `onAppear` → `viewModel.send(.appendExplore)`. **Integration edit:** in `TabItem.swift`, wrap the home closure `#if os(tvOS) { BrunoHomeView() } #else { HomeView() } #endif`. **Accept:** **both** tvOS AND iOS schemes build green; tvOS app shows the Bruno home of the real library; native focus works; card → stock detail; **Play works**.

**T6 — Hero / spotlight:** `BrunoHeroView` seeded 5-item spotlight (stable superset + seeded shuffle, §D), Oswald title + meta + Play/More; Play → `router.route(to: .item(item:))` (proto). **Accept:** build green; seeded feature renders.

**T7 — Group rows from the owner's BoxSets** (§E): Collections row (7 group tiles), Browse by Director (Directors children, portrait), Eras (Decades children), Studio/Genre/Curated lenses, date-aware Seasonal. Each opens its native collection grid. **Accept:** build green; rows show real curated art and drill in.

**T8 — Polish** (time-boxed; keep stock detail/player): Oswald headers; brand bg tint where cheap; `prefers-reduced-motion` guard; watched ✓ overlay if trivial. **Accept:** build green; reads as the same product family as `Bruno_standalone.html`.

**T9 — Final gates + handback:** tvOS compile gate green **AND** iOS gate green (`xcodebuild -scheme Swiftfin -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`); SwiftFormat/SwiftLint clean; unit tests (RNG + `build(seed)` determinism) pass; update `BRUNO_NOTES.md` with owner device-run steps + deferred TODOs; push `bruno`; open PR on origin. **Accept:** §G met.

---

## G. Definition of done
- [ ] `Swiftfin tvOS` **and** `Swiftfin` (iOS) both compile green (`generic/platform` destinations).
- [ ] Rebranded: accent `#A1CCE0`, Oswald/Inter, name "Bruno".
- [ ] `BrunoHomeView` is the tvOS Home tab (iOS keeps stock Home); shows the real library as hero + §E shelves.
- [ ] `BrunoHomePlan.build(seed:snapshot:)` pure/deterministic (unit-tested); `mulberry32` matches JS (unit-tested); Shuffle re-rolls; explore tail appends on scroll; seed day-stable; no `sortBy=.random` on stable shelves.
- [ ] Group rows come from the owner's favorited BoxSets and open native collection grids; empty shelves dropped.
- [ ] Card → stock detail → **Play works** (player/nav/detail unmodified).
- [ ] Changes additive; only the `#if os(tvOS)` tab swap touches a shared file. Secrets uncommitted.
- [ ] `BRUNO_NOTES.md`: verified signatures + owner device-run steps + deferred TODOs.

## H. Anti-goals / traps (from the red-team)
- Don't rebuild player/nav/detail. Don't hardcode a sim device name (use `generic/platform=tvOS Simulator`; `-downloadPlatform tvOS` first). Don't expect Carthage to fetch JellyfinAPI (it's SPM). Don't apply `@Stateful` to `BrunoHomeViewModel` or call `.send` on a paging VM. Don't swap `TabItem.home` globally (use `#if os(tvOS)`). Don't use `sortBy=.random` for reproducible shelves. Don't use plain `*`/`+` in `mulberry32` (use `&*`/`&+`). Don't depend on a network font download. Don't trust `minCommunityRating` until T0 verifies it. Don't hardcode item IDs — derive from the snapshot.
