# Bruno tvOS — Handoff (current)

> Supersedes the earlier UI handoff notes. Single source of truth for the next thread.
> Owner runs Bruno on a real **Apple TV ("Living Room")** and has low tolerance for churn —
> read §0 and §1 before touching anything.

## 0. WHERE TO WORK (read first)
- Work in the **MAIN checkout** `/Users/danielbrunelle/Documents/Claude/Projects/bruno` on branch
  **`main`**. That is exactly what Xcode builds. Commit there, push `origin/main`.
- **Do NOT create git worktrees or feature branches.** A prior thread's worktree + `bruno` +
  `claude/*` branch sprawl cost the owner hours of "where are my changes" confusion. It's been
  consolidated to **one branch: `main`** (local == `origin/main`). Keep it that way.
- At time of writing: `main` == `origin/main` == `d0d6e32f`.

## 1. "I built but don't see my changes" = stale DELIVERY, not code (this ate a whole session)
Check in order:
1. **Checkout behind `origin/main`** → `git pull` / fast-forward.
2. **Stale DerivedData** (it grew to 13 GB; Clean Build Folder did NOT clear it) → quit Xcode,
   `rm -rf ~/Library/Developer/Xcode/DerivedData`, reopen (re-resolves SPM; re-prompts **Trust &
   Enable** for the Swift macros — accept), rebuild.
3. **"Failed to update" on install = the new binary never reached the TV**, so Xcode relaunches the
   OLD app → on the Apple TV, **delete the Bruno app** (hold icon → Play/Pause → Delete), then Run.
   After a fresh install, subsequent Runs update fine.

**Ground truth marker:** a **`BUILD <Mon d · HH:mm:ss>` stamp top-right of the Home screen**
(`BrunoHomeView.buildStamp`, reads the executable mod-date). If it isn't ~now after a build, you're
on a stale install — fix delivery, don't debug code. (Temporary diagnostic; strip when owner is happy.)

## 2. Build recipe (headless verify)
```
cd /Users/danielbrunelle/Documents/Claude/Projects/bruno
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation -derivedDataPath /tmp/dd build
```
VLC frameworks (`Carthage/`) live in the main checkout. Finish a branch with a **clean** build —
incremental builds hide `@available` errors; use the repo's `.backport.<api>(…)` for tvOS-18 APIs.

## 3. DONE & on `main` (build-green) — needs ON-DEVICE eyeballing
- **Tabs:** Search leads, Settings trails, app opens on Home.
- **Home:** Shuffle removed; hero first-load layout-jump fixed; hero is one focusable element,
  left/right cycles spotlights, dots are a passive indicator; ambient backdrop is **one fixed still**.
- **Scroll perf:** library grids set the cinematic backdrop **once** instead of re-blurring a
  full-res cover on every focus (`Shared/Objects/Libraries/ItemLibrary.swift`).
- **Collections** (`BrunoCategoryShelves`): the category row is **big gradient cards** (group
  artwork) — tapping one **jumps straight to that category's Show-all**. Below, each shelf is the
  custom **`BrunoShelfRow`**: ~36 lazily-loaded items + a **trailing "Show all" card** (not a header
  button). Shelf children are **filtered to box sets** so the Directors shelf shows only directors,
  not every movie inside them. Item cards are portrait.
- **Boxed Sets** collection = all box sets minus the 7 curated groups + their children.
- **Genres** page: core-category panel (Action · Sci-Fi & Fantasy · Romance · Comedy · Drama) →
  per-core drill, mixed sub-genre shelves below.
- **Kids** (`BrunoKidsView`): merges the matched kids libraries; **All / Movies / TV Shows** filter
  as bubble cards on an opaque bar.
- **Audio night mode** (#4): `AudioNightMode` + VLC `compressor` hook work — but the **settings
  control is not visible** (see §4.1).

## 4. OUTSTANDING WORK
1. **Night-mode audio control missing from tvOS Settings (TOP PRIORITY).** #4 added the picker to
   `Swiftfin tvOS/Views/SettingsView/VideoPlayerSettingsView.swift`, but that view has **no
   references in the tvOS target** — it isn't wired into the tvOS settings navigation. Trace the
   tvOS Settings → Video Player flow (`SettingsView` + its coordinator / `NavigationRoute`s), find
   where playback settings actually render on tvOS, and surface the `AudioNightMode` picker there.
   Verify on-device it affects playback (filter applies at media-open; a level change likely needs a
   re-open/seek). Code: `Shared/Objects/AudioNightMode.swift`,
   `Shared/Objects/MediaPlayerManager/MediaPlayerProxy/MediaPlayerProxy+VLC.swift`.
2. **On-device verification of the shelves** (`BrunoShelfRow`, build-green but UNTESTED on hardware):
   Show-all card alignment vs poster cards, lazy scroll past ~36, focus, and that Directors really
   shows only directors now.
3. **Owner feedback still pending** on the big gradient category cards and the Kids filter look.

## 5. Key files
- Tabs: `Shared/Coordinators/Tabs/MainTabView.swift`, `TabItem.swift`, `TabCoordinator.swift`
- Home/hero: `Swiftfin tvOS/Views/BrunoHomeView/BrunoHomeView.swift`, `BrunoHeroView.swift`, `BrunoAmbientBackground.swift`
- Collections/shelves: `BrunoCollectionsView.swift`, `BrunoCategoryShelves.swift`, `BrunoShelfRow.swift`, `BrunoStaticItemsLibrary.swift`
- Genres/Kids: `BrunoGenresView.swift`, `BrunoBoxSetShelvesView.swift`, `BrunoKidsView.swift`, `BrunoCombinedLibrary.swift`
- Library grid / perf: `Shared/Objects/Libraries/ItemLibrary.swift`; cards: `Swiftfin tvOS/Components/PosterButton.swift`, `PosterHStack.swift`
- Data: `Shared/Objects/Bruno/BrunoLibrarySnapshot.swift`
- Audio: `Shared/Objects/AudioNightMode.swift`, `MediaPlayerProxy+VLC.swift`, `Swiftfin tvOS/Views/SettingsView/VideoPlayerSettingsView.swift`
- Other docs: `docs/DEPLOYMENT_HANDOFF.md` (signing), `docs/TOP_SHELF_SETUP.md`, `docs/UI_POLISH_ROADMAP.md`

## 6. Server assumptions (owner-curated; adjust if a tab/drill looks wrong)
- Kids libraries match the keyword `kids`. Collections groups matched by name (`Genres`/`Decades`
  drive the drills). Boxed Sets = box sets not in the 7 groups.
