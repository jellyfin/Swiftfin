# Handoff — Bruno tvOS deep UI work

> **Audience:** the next thread, picking up the heavy UI items after the tab IA landed.
> **Read first:** `docs/UI_POLISH_ROADMAP.md` (full spec + locked decisions) and
> `docs/DEPLOYMENT_HANDOFF.md` (real-device build: needs tvOS SDK + Swift-macro trust).
> **State:** Bruno runs on the owner's real Apple TV. Icons + hero auto-cycle + tab IA are done.

## What's already done (don't redo)
- **App icons** — `B.` / `BRUNO.` (white Oswald + round `#A1CCE0` dot on `#14120F`) wired into
  both asset catalogs + tvOS top-shelf banners. Source SVGs were in `/tmp/bruno-icons/` (ephemeral).
- **Hero auto-cycles** — added an 8s `Timer.publish` to `BrunoHeroView` (wraps, gated on Reduce Motion).
- **Tab IA (tvOS)** — `MainTabView.swift` order is now **Home · Movies · TV Shows · Collections ·
  Kids · Search · Settings**; `Media` dropped. `TabItem.collections` / `TabItem.kids` open Jellyfin
  libraries by name via the new `Swiftfin tvOS/Views/BrunoHomeView/BrunoUserViewLibraryTab.swift`.
  - The owner's Jellyfin **Kids** library lives at `/Volumes/Media Server NAS/Kids` (with
    `Movies` + `Shows` subfolders). The tab matches the user view whose display name == "Kids".
  - **Verify the names match.** `BrunoUserViewLibraryTab` matches case-insensitively on the
    library display name ("Collections", "Kids"). If a tab shows "Couldn't find …", the server's
    library is named differently — adjust the `viewName` passed in `TabItem`.

## Newly reported bugs (hand these off — NOT yet fixed)

### Hero banner (`BrunoHeroView.swift`)
1. **Hero artwork doesn't change on cycle** — the title/meta/overview update each tick and the
   blurred **ambient background DOES cycle**, but the main hero `ImageView` (backdrop) stays on the
   first image. Likely the `ImageView` isn't re-fetching when `current` changes — try forcing a
   reload with `.id(current.id)` on the `ImageView` (or key the whole hero content on the item id).
2. **Focus dips / UI jumps on auto-advance** — when the 8s timer fires, the layout/focus drops down
   unless the remote was just used. The focus engine loses its anchor when hero content swaps under
   it. Needs `@FocusState` management (or `focusSection`/`prefersDefaultFocus`) so the swap doesn't
   yank focus; and the timer probably shouldn't mutate focused content.
3. **Hero focus model is wrong (desired behaviour):** no selection highlight, no button-press on the
   dots to cycle. Instead — **one click down from the top menu should invisibly land on the hero**,
   and **left/right should auto-increment the spotlight like a content shelf** (dots become a
   non-interactive page indicator, not focusable buttons). Rework the dot `Button`s → indicator +
   directional move-command handling.

### Kids tab (`BrunoUserViewLibraryTab.swift` / `TabItem.kids`)
4. **Kids doesn't resolve** — there is **no single "Kids" user view**; the owner's Kids content is
   split into separate **Shows** and **Movies** libraries (paths `…/Kids/Movies`, `…/Kids/Shows`).
   So matching `viewName == "Kids"` finds nothing. Fix options: point the tab at the actual library
   name(s), or aggregate both Kids libraries into one view (match multiple names, or filter by the
   parent "Kids" folder id). Confirm the exact Jellyfin display names with the owner.

## Deep work remaining

### A. Collections page — category row + per-category shelves  (roadmap §3)
Today the Collections library is a flat poster grid of the 7 curated **group BoxSets**
(Directors, Decades, Studios, Genres, Curated, Seasonal, New Releases — see
`Shared/Objects/Bruno/BrunoLibrarySnapshot.swift`). Target:
- Keep the **category row** across the top.
- One **horizontal-scroll shelf per category**, single line, **capped at ~12 items**.
- Trailing **"Show all" card** → routes to the full grid for that category.
- Build on the existing Bruno shelf components — `BrunoShelfView` / `BrunoShelfViewModel` already
  render capped horizontal carousels on the Home tab; reuse them rather than inventing new ones.
- Full grid destination already exists (`ItemLibrary(parent: boxSet)` → `PagingLibraryView`, the
  same route `UserViewLibraryElement.libraryDidSelectElement` uses).

### B. Genres & Decades — same shelf pattern  (roadmap §4)
Inside Genres and Decades, mirror §A: a shelf per sub-category (each genre / each decade), capped,
with **"Show all" → full grid** of that sub-category. Same components as §A.

### C. System Top Shelf — dynamic previews  (roadmap §1b — "previews like the Apple TV app")
This is the big one and its own target.
- Add a **Top Shelf extension** target (`TVTopShelfContentProvider`) returning sectioned
  `TVTopShelfSectionedItem`s — Continue Watching / Recently Added / featured, with poster art.
- **Auth plumbing is the crux:** the extension is a separate process, so it needs the saved
  server URL + access token. Share them via an **App Group + shared keychain access group**
  (the keychain access group already declared for on-device sign-in — see DEPLOYMENT_HANDOFF §1 —
  is the hook; the main app must write session creds where the extension can read them).
- Each item's `displayAction` should **deep-link** into Bruno (wire to the existing
  `deepLinkHandler` used in `MainTabView`).
- Keep the static `BRUNO.` top-shelf image as the fallback when there's no auth/content.

### D. Hero refinement (optional, roadmap §1)
Pause the hero auto-advance while the hero row / a button is focused (TV-app behaviour).

## Build & verify reminders
- New `.swift` files auto-compile — the project uses **PBXFileSystemSynchronizedRootGroup** (no
  `.pbxproj` edits needed); just drop files in the synced folders.
- First build on a fresh machine: install the **tvOS SDK** and **Trust & Enable** the Swift macros
  (`Defaults`, `swift-case-paths`, `StatefulMacro`, `Engine`).
- Build tree = the **main checkout**; scheme "Swiftfin tvOS"; Team ID in gitignored
  `XcodeConfig/DevelopmentTeam.xcconfig`. There are uncommitted local changes (icons + this IA work).

## Grounding files
- Tabs: `Shared/Coordinators/Tabs/MainTabView.swift`, `TabItem.swift`, `TabCoordinator.swift`
- New: `Swiftfin tvOS/Views/BrunoHomeView/BrunoUserViewLibraryTab.swift`
- Shelves/home: `Swiftfin tvOS/Views/BrunoHomeView/BrunoShelfView.swift`, `BrunoShelfViewModel.swift`, `BrunoHomeView.swift`, `BrunoHeroView.swift`
- Collections data: `Shared/Objects/Bruno/BrunoLibrarySnapshot.swift`, `BrunoHomePlan.swift`, `BrunoQueryLibrary.swift`
- Single-library route pattern: `Shared/Objects/Libraries/UserViewLibrary.swift` (`libraryDidSelectElement`)
- Brand: `Shared/Extensions/Color.swift` (`Color.bruno.*`), `Font+Bruno.swift`
