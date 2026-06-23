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
- [ ] Pause auto-advance while the hero row is focused / a button is focused (TV-app behaviour).

## 1b. System Top Shelf — dynamic content (DECIDED: this is the "previews like Apple TV app")
- [ ] Build a **Top Shelf extension** (new app-extension target, `TVTopShelfContentProvider`)
  that returns sectioned poster items (Continue Watching / recent / featured) above the icon row.
- [ ] **Auth sharing:** the extension runs in its own process — it needs the saved server +
  token via an **App Group / shared keychain access group** (the keychain group already declared
  for device sign-in is the hook). This is the main plumbing.
- [ ] Tapping a Top Shelf poster deep-links into the item (wire to the existing deep-link handler).
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

## 3. Collections page — category row + per-category shelves
Today: category row (NEW RELEASES, DIRECTORS, DECADES, GENRES, STUDIOS, CURATED, SEASONAL)
over one big poster grid.
- [ ] Keep the **category row across the top**.
- [ ] Beneath it, **one horizontal-scroll shelf per category**, single line each.
- [ ] **Cap each shelf at ~12 items**, then a trailing **"Show all" card**.
- [ ] "Show all" → routes to the **full grid** for that category.

## 4. Genres & Decades — same shelf pattern
- [ ] Inside **Genres** and **Decades**, mirror §3: a shelf per sub-category (each genre /
  each decade), capped, with a **"Show all" → full grid** of that sub-category's contents.

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
