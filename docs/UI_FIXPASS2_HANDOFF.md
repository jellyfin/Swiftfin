# Handoff — Bruno tvOS UI fix pass #2 (in-flight)

> For the next thread. The owner is testing on a **real Apple TV ("Living Room")** and is
> frustrated after a long stale-build detour (see §0 — read it first, it will save you hours).
> Two jobs: **(A) finish the Collections shelf rework** below, and **(B) surface the night-mode
> audio controls in Settings** (they exist in code but aren't visible on tvOS).

---

## 0. CRITICAL OPERATIONAL KNOWLEDGE (the thing that ate this session)

**Symptom:** "I built and pushed to my TV but I don't see the changes."
**Cause it was NOT:** the code/merges (those were correct the whole time).
**Actual causes, in order of how much pain they caused:**

1. **The build checkout was a commit behind** — fast-forward the main checkout (`/Users/danielbrunelle/Documents/Claude/Projects/bruno`, branch `bruno`) to `origin/main` before building.
2. **Stale DerivedData (was 13 GB).** Even Clean Build Folder didn't clear it. Fix: quit Xcode, `rm -rf ~/Library/Developer/Xcode/DerivedData`, reopen (it re-resolves SPM + may re-prompt **Trust & Enable** for the Swift macros — accept them), rebuild.
3. **"Failed to update" on install = the new binary never reached the device**, so Xcode relaunches the OLD installed app → you see old UI. **Fix: on the Apple TV, delete the Bruno app (hold icon → Play/Pause → Delete), then Run.** After a fresh install, subsequent Runs update fine.

**Ground-truth marker (KEEP THIS UNTIL THE OWNER SAYS OTHERWISE):** there is a **`BUILD <Mon d · HH:mm:ss>` stamp in the top-right of the Home screen** (`BrunoHomeView.buildStamp`, reads the executable's mod-date). If that time isn't "now" after a build, you're looking at a stale install — do NOT debug the code, fix the install (§0.3).

**Build recipe (headless verify, in a worktree):**
```
ln -s /Users/danielbrunelle/Documents/Claude/Projects/bruno/Carthage <worktree>/Carthage   # gitignored VLC frameworks
xcodebuild -project Swiftfin.xcodeproj -scheme "Swiftfin tvOS" \
  -destination 'generic/platform=tvOS Simulator' -skipMacroValidation -derivedDataPath /tmp/dd build
```
Finish a branch with a **clean** build — incremental builds hide `@available` errors. Use the repo's
`.backport.<api>(…)` wrapper for SwiftUI APIs newer than the deployment target.

---

## 1. Repo state

- Merged to `main` (fork `DiplomacyMusic/swiftfin-bruno`): PR #2 (deep UI), PR #3 (fix pass), PR #4 (audio night mode). HEAD `88795a43`.
- **In-flight, build-GREEN, committed as WIP on this handoff (see git log):** four files —
  - `Shared/Objects/Libraries/ItemLibrary.swift` — cinematic background now **set-once** (perf).
  - `Swiftfin tvOS/Views/BrunoHomeView/BrunoHomeView.swift` — ambient backdrop is **one fixed still** (first hero) instead of the cycling one; also holds the `buildStamp`.
  - `Swiftfin tvOS/Views/BrunoHomeView/BrunoCategoryShelves.swift` — category row is now **big gradient cards** (the group artwork) that **jump straight to Show-all** (`routeToShowAll`); the small scroll-jump pills are gone.
  - `Swiftfin tvOS/Views/BrunoHomeView/BrunoKidsView.swift` — filter is **bigger bubble cards** on an **opaque bar** (no longer floats over the grid).

---

## 2. JOB A — finish the Collections shelf rework (owner's latest asks, NOT yet done)

These came in after the WIP above and are the immediate work:

1. **"Show all" must be the LAST CARD in each horizontal shelf — not a button/bubble in the header.**
   `PosterHStack.trailing` is a **no-op** in this codebase, so you must build a small custom shelf
   on `CollectionHStack` directly (see how `Swiftfin tvOS/Components/PosterHStack.swift` uses it:
   `CollectionHStack(uniqueElements:columns:).dataPrefix(20).insets(…).itemSpacing(…).scrollBehavior(.continuousLeadingEdge)`).
   Use a mixed element enum, e.g. `enum ShelfCard { case item(BaseItemDto); case showAll }`,
   render `PosterButton` for items and a styled "Show all" card for the trailing one (route via the
   existing `routeToShowAll(category)` in `BrunoCategoryShelves`).
2. **~3× more items before the Show-all card** (cap ≈ 36, lazily loaded). The current `shelfCap = 12`
   and `PosterHStack`'s `.dataPrefix(20)` both limit this — your custom shelf should `dataPrefix`
   ~40 and the Collections data already fetches up to 200 children (`BrunoLibrarySnapshot.fetchChildren`).
3. **Shelves must show only the sub-collections, not loose movies.** Bug: the **Directors** shelf
   shows the director collections and then **all the movies inside every director group**. Filter
   each `category.children` to collections (`type == .boxSet`) for the shelf, falling back to all
   children if none are box sets (so a genuinely flat group like New Releases still shows). The
   "Show all" grid can still show everything.
4. Item cards stay **portrait** (owner confirmed). The big gradient **category cards** at the top are
   correct — don't revert those.

Grounding files: `Swiftfin tvOS/Views/BrunoHomeView/BrunoCategoryShelves.swift` (shelf + category row),
`BrunoCollectionsView.swift` (data/VM), `Swiftfin tvOS/Components/PosterHStack.swift` +
`PosterButton.swift` (card building blocks), `Shared/Objects/Bruno/BrunoLibrarySnapshot.swift` (children).

## 3. JOB B — surface the night-mode audio controls in Settings

Owner doesn't see the night-mode control in Settings on the Apple TV. PR #4 added:
`Shared/Objects/AudioNightMode.swift` (the `AudioNightMode` enum + libVLC `compressor` options),
a hook in `Shared/Objects/MediaPlayerManager/MediaPlayerProxy/MediaPlayerProxy+VLC.swift`, a
`Defaults` key, `L10n` strings, and edits to `Swiftfin tvOS/Views/SettingsView/VideoPlayerSettingsView.swift`.

**Likely cause:** a `grep` for `VideoPlayerSettingsView` across `Swiftfin tvOS/` returned **no
references** — i.e. the picker may have been added to a view that the tvOS settings navigation
doesn't actually present (or it's gated to a player type / behind a row the owner didn't reach).
Next steps: trace the tvOS Settings → Video Player navigation (`SettingsView` + its coordinator /
`NavigationRoute`s), confirm where playback settings render on tvOS, and surface the `AudioNightMode`
picker there. Verify on-device that changing it actually affects playback (the filter applies at
media-open, so a level change may need a re-open/seek — see `docs/` night-mode notes / the audio task).

## 4. Things to keep in mind
- The `BUILD` stamp is a temporary diagnostic in `BrunoHomeView`. Keep it until the owner is happy,
  then strip it.
- Owner-curated server names matter: Kids matches a `kids` keyword; Collections groups are matched
  by name (`Genres`/`Decades` drive the drills). Boxed Sets = all box sets minus the 7 groups + their children.
- The owner is on a real device and short on patience — verify the **install actually updated**
  (build stamp) before claiming anything is fixed.
