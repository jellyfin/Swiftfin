# Bruno UI polish roadmap (tvOS)

> Captured 2026-06-23 after real-device install succeeded. The "streamer gloss" Home,
> collection grid, and shelves are in; this is the next push — making the IA and browse
> surfaces feel like the Apple TV app. iOS is intentionally deferred (stock Swiftfin + rebrand).

## Status legend
- [ ] not started · [~] in progress · [x] done

---

## 1. Home hero — "previews like the Apple TV app"
- [x] **Auto-cycling spotlight.** `BrunoHeroView` was labelled "rotating spotlight" but never
  had a timer — `index` only changed on dot tap. Added an 8s `Timer.publish` auto-advance
  (wraps, gated on `!reduceMotion` and `items.count > 1`). `Swiftfin tvOS/Views/BrunoHomeView/BrunoHeroView.swift`.
- [x] **Pause auto-advance while focused** (TV-app behaviour) — plus two more hero fixes shipped
  together: the backdrop now actually re-fetches on cycle (`.id(item.id)` + cross-fade), and the
  dots became a passive page indicator while the whole hero is one chrome-less focusable element
  whose left/right move-commands cycle the spotlight. Focus *feel* needs an on-device pass.

## 1b. System Top Shelf — dynamic content (DECIDED: this is the "previews like Apple TV app")
- [~] **Groundwork shipped; target creation is the owner's (needs Xcode + App Group + signing).**
  - [x] `BrunoTopShelfCredentials` cross-process bridge (App Group `UserDefaults`), written by
    `UserSession.start()` and cleared on sign-out — a no-op until the App Group exists.
  - [x] `TVTopShelfContentProvider` (Continue Watching / Recently Added, poster art, deep links via
    the existing `swiftfin://…/item/<id>` scheme) + Info.plist + entitlements, as ready-to-add
    template files in `BrunoTopShelf/` (not compiled).
  - [ ] Owner: create the extension target, add the App Group to both targets, sign. Full
    step-by-step in **docs/TOP_SHELF_SETUP.md**.
- Static `BRUNO.` top-shelf image stays as the fallback when no content/auth is available.

## 2. Top bar / tab IA  — `Shared/Coordinators/Tabs/MainTabView.swift` (tvOS branch)
Current tvOS order: **Home · TV Shows · Movies · Search · Media · Settings**
**DECIDED target order: Home · Movies · TV Shows · Collections · Kids · Search · Settings**
- [ ] **Add `TabItem.kids`** → points at the owner's **existing Jellyfin kids library/folder(s)**
  (they already exist as their own folders/libraries on the server — NEED EXACT NAME(S)).
  Build like `TabItem.library(...)` but target the user-view/library by id rather than item-type filters.
- [ ] **Replace "Media" with "Collections"** (`TabItem.media` → `TabItem.collections`,
  pointing at the redesigned Collections hub in §3). `Shared/Coordinators/Tabs/TabItem.swift`.
- [ ] **Drop the redundant Media tab** (`UserViewLibrary`) — duplicated Movies + TV Shows.
- [ ] **Search + Settings at the end.**

## 3. Collections page — category row + per-category shelves  ✅ DONE
- [x] **Category row across the top** (scroll-jumps to each shelf).
- [x] **One horizontal shelf per category**, single line each (`BrunoCategoryShelves`).
- [x] **Capped at ~12 items** + a **"Show all"** — in the shelf header (PosterHStack's trailing
  slot is a no-op in this codebase), routing to the **full grid** for that category.
  - `Swiftfin tvOS/Views/BrunoHomeView/BrunoCollectionsView.swift` + `BrunoCategoryShelves.swift`.
  - Category-row scroll-jump + focus landing want an on-device pass (LazyVStack + `scrollTo`).

## 4. Genres & Decades — same shelf pattern  ✅ DONE
- [x] Genres/Decades "Show all" drills into `BrunoBoxSetShelvesView`: a shelf per sub-category
  (each genre / each decade), capped, with **"Show all" → full grid** of that sub-category.
  Reuses `BrunoCategoryShelves`; gated on group name + the live BoxSet-of-BoxSets shape.

---

## Decisions locked (2026-06-23)
1. **Previews = system Top Shelf** (§1b), not the in-app hero.
2. **Tab order = Home · Movies · TV Shows · Collections · Kids · Search · Settings.**
3. **Kids = existing Jellyfin kids libraries/folders.** Still need the **exact library name(s)/id(s)**.

## Remaining blocker
- Exact name(s) of the Kids libraries/folders on the Jellyfin server, to target `TabItem.kids`.

## Reference (grounding files)
- Home: `Swiftfin tvOS/Views/BrunoHomeView/BrunoHomeView.swift`, `BrunoHeroView.swift`, `BrunoShelfView.swift`
- Shelf model: `Shared/Objects/Bruno/BrunoShelf.swift`, `BrunoQueryLibrary.swift`, `BrunoHomePlan.swift`
- Tabs: `Shared/Coordinators/Tabs/MainTabView.swift`, `TabItem.swift`, `TabCoordinator.swift`
- Brand: `Shared/Extensions/Color.swift` (`Color.bruno.*`), `Font+Bruno.swift` (Oswald/Inter)
