# BRUNO_NOTES.md — verified signatures, environment, and handback

> Source of truth for the Bruno tvOS fork. Created during T0 by re-verifying every signature the
> plan (`NATIVE_FORK_PLAN.md`) lists against the **actual local source** (Swiftfin + the resolved
> `jellyfin-sdk-swift` 2.1.0) and the **live Jellyfin library**. Where this file and the plan differ,
> **this file wins** (the plan invited T0 to override on drift).
>
> **No secrets in this file.** Live Jellyfin creds live only in the gitignored `bruno_jellyfin.env`.

---

## §Toolchain

**Now on Xcode 26.3 (Swift 6.2.4, iOS/tvOS 26.2 SDKs) — the toolchain this fork was authored for.**
All the `Bruno toolchain-compat` workarounds have been **reverted**; the fork builds as authored
(Nuke 13.0.2, Pulse 5.2.0, isolated conformance, Liquid Glass `glassEffect`, `cornerConfiguration`),
with Bruno added on top.

| Thing | Value |
|---|---|
| Xcode | 26.3 (17C529), Swift 6.2.4 |
| SDKs | tvOS 26.2, iOS 26.2 (installed via Xcode); macOS host |
| tvOS sim runtime | tvOS 18.5 present (satisfies the `generic/platform=tvOS Simulator` compile gate). To *run* on the sim, install a tvOS 26 runtime; deploying to a physical Apple TV needs no sim runtime. |
| Carthage | VLCKit only: `MobileVLCKit.xcframework` + `TVVLCKit.xcframework` under `Carthage/Build/` |
| SPM | JellyfinAPI 2.1.0, StatefulMacros 0.1.4, Nuke 13.0.2, Pulse 5.2.0, Defaults 9.0.2, etc. |
| Dev team xcconfig | `XcodeConfig/DevelopmentTeam.xcconfig` (gitignored): `DEVELOPMENT_TEAM = ABCDE12345`, `PRODUCT_BUNDLE_IDENTIFIER = com.diplomacymusic.bruno` |

### THE COMPILE GATE (`-skipMacroValidation` keeps CLI macro trust from blocking the first build)
```bash
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation build CODE_SIGNING_ALLOWED=NO
```
iOS gate: `-scheme Swiftfin -destination 'generic/platform=iOS' -skipMacroValidation` (needs the iOS 26.2
platform installed — `xcodebuild -downloadPlatform iOS`; the simulator destination additionally needs an
iOS 26 sim runtime). Without `-skipMacroValidation` the build can die at `ComputeTargetDependencyGraph`
with `Macro "CasePathsMacros"/"StatefulMacrosMacros" ... must be enabled before it can be used`.

### History (for reference): building on the earlier Xcode 16.4
This fork's source + `Package.resolved` target Xcode 26, so on the original Xcode 16.4 (Swift 6.1.2 /
tvOS 18.5 SDK) it would not compile. The bridge — now all reverted — pinned Nuke 13→12.9.0 (+ a
`ImagePipeline.Delegate`→`ImagePipelineDelegate` rename), Pinned Pulse 5.2→5.1.4, replaced the
`@MainActor Identifiable` isolated conformance with a captured `nonisolated let _id`, and routed
`glassEffect` / `cornerConfiguration` to their legacy fallbacks. If you ever need to build on a pre-26
Xcode again, see git history around commit `3476b66b`.

### GitHub Actions disabled (per owner)
`.github/workflows/{ci.yml,testflight.yml,validate-pr.yaml}` renamed to `*.disabled` so no heavy
macOS CI runs on push/PR. Re-enable by removing the `.disabled` suffix.

---

## §SDK signatures (jellyfin-sdk-swift 2.1.0 — checked in DerivedData/SourcePackages/checkouts)

`Paths.GetItemsParameters` (file `Sources/Paths/GetItemsAPI.swift`) — all fields the plan needs EXIST:
- `userID: String?`, `startIndex: Int?`, `limit: Int?`, `isRecursive: Bool?`, `searchTerm: String?`
- `parentID: String?`, `fields: [ItemFields]?`, `includeItemTypes: [BaseItemKind]?`
- `filters: [ItemFilter]?`, `sortBy: [ItemSortBy]?`, `sortOrder: [SortOrder]?`
- `genres: [String]?`, `years: [Int]?`, `personIDs: [String]?`, `studioIDs: [String]?`
- `enableUserData: Bool?`, `enableTotalRecordCount: Bool?`, `nameStartsWith: String?`
- **`minCommunityRating: Double?` — EXISTS** (verified server-side too: `MinCommunityRating=8.2` → 39 movies).
  So Hero/Acclaimed can use it directly; no client-side fallback needed.

Enum cases (verified):
- `ItemFilter`: `.isFavorite` ("IsFavorite"), `.isUnplayed` ("IsUnplayed"), `.isPlayed`, `.isResumable`, …
- `ItemSortBy`: `.dateCreated`, `.premiereDate`, `.sortName`, `.random`, `.communityRating`,
  `.productionYear`, `.criticRating`, `.seriesSortName`, …
- `SortOrder`: `.ascending`, `.descending`  (type is `SortOrder`, NOT `ItemSortOrder`)
- `ItemFields`: `.genres`, `.mediaSources`, `.overview`, `.people`, … plus Swiftfin's static
  `[ItemFields].MinimumFields` (in `Shared/Extensions/JellyfinAPI/ItemFields.swift`) used as
  `parameters.fields = .MinimumFields`.

API call shape (from `RecentlyAddedLibrary.retrievePage`):
```swift
var parameters = Paths.GetItemsParameters()
parameters.userID = pageState.userSession.user.id
parameters.limit = pageState.pageSize
parameters.startIndex = pageState.pageOffset
let request = Paths.getItems(parameters: parameters)
let response = try await pageState.userSession.client.send(request)
return response.value.items ?? []   // .totalRecordCount when enableTotalRecordCount = true
```
Special endpoints: `Paths.getResumeItems`, `Paths.getNextUp`, `Paths.getPersons`, `Paths.getGenres`.

---

## §Swiftfin architecture (verified file:line)

**Paging library = 3 parts:**
1. A `struct: BaseItemKindLibrary` (`Shared/Objects/PagingLibrary/BaseItemKindLibrary.swift:11` —
   `protocol BaseItemKindLibrary: PagingLibrary where Element == BaseItemDto { var libraryItemTypes: [BaseItemKind] }`).
   Implement `func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [BaseItemDto]`.
   `LibraryPageState` (`PagingLibrary.swift:12`) = `{ pageOffset: Int; pageSize: Int; userSession: UserSession }`.
   Templates: `Shared/Objects/Libraries/{RecentlyAddedLibrary,NextUpLibrary,ResumeItemsLibrary,LatestInLibrary,ItemLibrary}.swift`.
2. `PagingLibraryViewModel<Library>(library:)` — `Shared/Objects/PagingLibrary/PagingLibraryViewModel.swift:18`.
   It IS `@Stateful(conformances: [WithRefresh.self])` (the macro). `@Published var elements: IdentifiedArrayOf<Element>`.
   **Refresh with `await vm.refresh()`** (the `WithRefresh` async method, `Shared/Objects/WithRefresh.swift:17`),
   page with `vm.send(.getNextPage)` or `vm.getNextPage()`. Do NOT call `.send(.refresh)` style on it from Bruno —
   use `await vm.refresh()`.
3. tvOS section view: `PosterHStack(title:type:items:) { item in router.route(to: .item(item: item)) }`.

**PosterHStack (tvOS)** `Swiftfin tvOS/Components/PosterHStack.swift:14` — action is **single-arg `(Element) -> Void`**:
```swift
init(title: String? = nil, type: PosterDisplayType, items: Data,
     action: @escaping (Element) -> Void,
     @ViewBuilder label: ... = { PosterButton<Element>.TitleSubtitleContentView(item: $0) })
```
(iOS version is `(Element, Namespace.ID) -> Void` — so Bruno views stay in `Swiftfin tvOS/` only.)
Template `Swiftfin tvOS/Views/HomeView/Components/LatestInLibraryView.swift` guards `viewModel.elements.isNotEmpty`.

**Hand-written `Stateful`** `Shared/Objects/Stateful.swift:11` — `associatedtype Action: Equatable`,
`State: Hashable`, `func respond(to:) -> State`, `func send(_:)` (extension sets `state = respond(to:)`).
`HomeViewModel` (`Shared/ViewModels/HomeViewModel.swift:17`) conforms to it: `final class HomeViewModel: ViewModel, Stateful`.
➜ **BrunoHomeViewModel copies this hand-written shape; do NOT apply the `@Stateful` macro to it.**

**Navigation** — `@Router private var router` (`Shared/Coordinators/Navigation/Router.swift:39`);
`router.route(to: .item(item: someBaseItemDto))` opens stock detail (Movie/Series/**Collection/BoxSet**),
defined `NavigationRoute+Item.swift:152` (`static func item(item:) -> NavigationRoute { ... ItemView(item: item) }`).

**TabItem** `Shared/Coordinators/Tabs/TabItem.swift:47` — `static var home: TabItem { TabItem(id:"home", title:L10n.home, systemImage:"house") { HomeView() } }`.
➜ wrap the trailing closure in `#if os(tvOS) BrunoHomeView() #else HomeView() #endif`.

**Images** `BaseItemDto+Images.swift:65` — `func imageSource(_ type: ImageType, index:..., maxWidth:..., maxHeight:..., quality:..., tag:...) -> ImageSource`.
`PosterDisplayType` (`Shared/Objects/PosterDisplayType.swift`) cases: **`.landscape`, `.portrait`, `.square`** (only three).
Use `.landscape` for backdrop shelves, `.portrait` for director/tile shelves.

**Color/theme** `Shared/Extensions/Color.swift:95` — `init(hex: String)` (supports 6/8-digit, optional `#`).
`Shared/Services/SwiftfinDefaults.swift:69` — `accentColor: Key<Color> = AppKey("accentColor", default: .jellyfinPurple)`
and `userAccentColor` (`UserKey(... default: .jellyfinPurple)`). Set both defaults to Bruno accent `#A1CCE0`.
Font helpers in `Shared/Extensions/Font.swift`.

**Info.plist (tvOS)** `Swiftfin tvOS/Resources/Info.plist` — `CFBundleName = $(PRODUCT_NAME)`; **no `UIAppFonts`**,
no `CFBundleDisplayName`. T1 must CREATE `UIAppFonts` (font filenames) and ADD `CFBundleDisplayName = Bruno`.

**Defaults / persistence** — `Defaults` (sindresorhus) + Swiftfin `StoredValues`. Simple session-scoped seed →
a `Defaults.Keys` `Key<Int>` is enough for the day-seed (see T4).

---

## §Live library snapshot (validated against http://192.168.50.19:8899 — server Jellyfin 10.10.3)

- **635 movies, 19 series, 162 BoxSets total.**
- **7 favorited group BoxSets** (these ARE the spec's groups — `IncludeItemTypes=BoxSet & Filters=IsFavorite`):
  `New Releases`, `Directors`, `Decades`, `Genres`, `Studios`, `Curated`, `Seasonal`.
  Their **children are sub-BoxSets** (e.g. Studios → 35 studio BoxSets like A24/20th Century Fox;
  Genres → genre BoxSets like Horror→20 movies; Decades → `1950s & Earlier`…`2020s`; Directors → auteur BoxSets).
  ➜ Discover groups dynamically as the favorited BoxSets; **never hardcode IDs** (they're derived per-snapshot).
- **Browse the Collection** shelf = the 7 group tiles → each opens its native collection grid.
- **Resume**: 14 items (movies+episodes) via `/Users/{uid}/Items/Resume?MediaTypes=Video`.
- **NextUp**: 5 via `/Shows/NextUp?userId={uid}`.
- **Genres**: 23 (`/Genres?userId=`). **Persons(Director)**: present (`/Persons?personTypes=Director`).
- **Hero/Acclaimed**: `MinCommunityRating=8.2 & IncludeItemTypes=Movie` → 39 (Shawshank 8.7, Godfather 8.7, …).
- Favorites & Resume & NextUp are **user-scoped** — must thread `userId` (Swiftfin does this via `pageState.userSession`).

---

## §Runtime smoke test (tvOS 18.5 Simulator)

Built `Swiftfin tvOS.app` was installed and launched on the Apple TV 4K (3rd gen) tvOS 18.5 sim:
the binary **runs without crashing**, fonts load, and the **Bruno sky-blue accent** renders
(Connect button) — confirming the rebrand is applied app-wide, not just in Bruno Home. Signing in
to the live Jellyfin (LAN) and rendering the Bruno Home is the **owner's on-device step** (tvOS
sign-in automation in the sim is out of scope); the data behind every shelf was validated
independently via the live API (see §Live library snapshot).

## §Owner device-run steps

1. Open `Swiftfin.xcodeproj` in Xcode 16.4 (or run the §LOCKED gate from the CLI).
2. Set a real `DEVELOPMENT_TEAM` in `XcodeConfig/DevelopmentTeam.xcconfig` (placeholder is `ABCDE12345`)
   and a unique `PRODUCT_BUNDLE_IDENTIFIER` (currently `com.diplomacymusic.bruno`).
3. Select the **Swiftfin tvOS** scheme + your Apple TV (or the tvOS 18.5 Simulator), and Run.
4. On first launch, add the Jellyfin server `http://192.168.50.19:8899` and sign in (creds in the local
   gitignored `bruno_jellyfin.env`). The Home tab is now **Bruno**: a seeded hero + the §E shelves of
   your real library. Tap a card → stock detail → **Play**. Tap **Shuffle** to re-roll the day's seed.
5. To run the determinism/RNG checks: `./bruno-verify/run.sh` (prints `ALL RNG CHECKS PASSED`). The
   plan determinism is also asserted at every `BrunoHomeViewModel.init` in DEBUG builds.

## §Deferred TODOs

- Direct hero-play (build `MediaPlayerItemProvider` → `.videoPlayer`) — proto uses `router.route(to:.item(item:))` (stock detail → Play).
- ~~Revert toolchain-compat edits + Nuke/Pulse pins once on Xcode 26~~ — **DONE** (now building on Xcode 26.3; fork restored to authored state).
- Localize Bruno UI strings via `L10n` (prototype is English-only; `hard_coded_display_string` is disabled in the two Bruno view files).
- Licensed Knockout font (Oswald is the brand stand-in).
- Hero auto-rotation (9s) — current hero is dot-switchable + seeded; auto-advance deferred to keep tvOS focus stable.
- A formal XCTest target (none exists in the fork) — RNG verified via `bruno-verify/`, determinism via DEBUG self-check.
