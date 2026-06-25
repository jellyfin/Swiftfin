# Bruno — Project Tracker

> Canonical, living status board for the Bruno tvOS fork. The **bruno-expert** agent owns this file
> and keeps it in sync. When you finish a unit of work, update the matching row here in the same change.
>
> Inputs that feed this tracker (read them, don't duplicate them):
> - Product contract: `prototype/design_handoff_bruno/PRODUCT_SPEC.md` + `README.md` (the mockup)
> - Verified architecture / signatures: `BRUNO_NOTES.md`
> - Build & run recipes: `docs/STATUS.md`, `docs/SIM_VIEWING_HANDOFF.md`, `docs/DEPLOYMENT_HANDOFF.md`
> - Next-push design intent: `docs/UI_POLISH_ROADMAP.md`
> - Top Shelf wiring: `docs/TOP_SHELF_SETUP.md`
>
> Status legend: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked

_Last synced: 2026-06-24 (snappiness pass + landscape-snap & pill fixes; scroll-reveal hitch root-caused & deferred). Update this date on every edit._

---

## Now / next (the active push: tvOS IA + browse polish)

| St | Item | Where | Notes / blocker |
|----|------|-------|-----------------|
| [ ] | Tab IA reorder → **Home · Movies · TV Shows · Collections · Kids · Search · Settings** | `Shared/Coordinators/Tabs/MainTabView.swift`, `TabItem.swift` | Decided 2026-06-23. Replace `Media`→`Collections`, drop redundant Media. |
| [!] | `TabItem.kids` → existing Jellyfin kids library/folder | `TabItem.swift`, `BrunoKidsView.swift` | **BLOCKED:** need exact Kids library name(s)/id(s) on the server. |
| [~] | System Top Shelf extension (dynamic previews) | `BrunoTopShelf/`, `BrunoTopShelfCredentials.swift` | Groundwork shipped; owner must create the target + App Group + signing. See `docs/TOP_SHELF_SETUP.md`. |
| [ ] | Night-mode / settings surface | (TBD) | Called out as outstanding in the latest handoff. Scope undefined. |
| [ ] | On-device shelf check (focus feel, scroll-jump landing) | Home / Collections / Genres | Category-row scroll-jump + hero focus feel want a real Apple TV pass. |
| [ ] | **Browse scroll-reveal hitch → fold into the Browse→Home redesign** | `BrunoCategoryShelves` (the `ForEach(categories){ shelf }` stack) | **Root cause found 2026-06-24, confirmed ON-DEVICE; refined diagnosis.** Each vertical shelf reveal freezes ~200-450ms (sim/Debug; less on device but real). The per-cell cost (CollectionHStack/CollectionVGrid both mint a fresh `UIHostingController` per cell, no reuse) is **identical in stock Swiftfin** — so it is NOT a Bruno bug and a dependency fork is NOT the right fix. **The deviation is structural:** stock uses carousels ONLY for the bounded curated Home spine and ONE recycling grid (`CollectionVGrid`/`PagingLibraryView`) for long/"see all" browse; Bruno's browse stacks 20-40 separate `CollectionHStack`s (one `UICollectionView` each, no cross-row recycling) → per-reveal mount burst. **"Comply with Swiftfin": route flat-category browse (Directors/Studios) to the grid Bruno already owns (`brunoItemsGrid`→`PagingLibraryView`); cap live carousels on multi-lens browse (Genres → "see all categories"→grid); keep carousels for the Home spine.** Same edit as item below (redesign owns `BrunoCategoryShelves`) — DO IT INSIDE THE REDESIGN, not standalone. Secondary polish: path-based `.posterShadow()` (keep the look). Levers that DON'T help: `dataPrefix` (already matched), `drawingGroup` (breaks focus). |
| [ ] | **Browse → Home realignment redesign** | Collections / Genres / Decades browse surfaces | Browse drifts from Home in 3 ways: (1) no persistent hero banner — **owner confirmed (2026-06-23) they want the cinematic featured-content banner (à la Home's `BrunoHeroView`, NOT a streamer logo) to persist across browse views**, (2) eyebrows are repeated group-names rather than lenses, (3) flat vs elevated posters. Make browse consistent with Home on color/type/spacing. Cheapen `.posterShadow()` *with* on-device measurement here (keep the shadow — it's brand, README.md:189-193); revisit `.hoverEffect(.highlight)` removal under measurement. Brief authored 2026-06-23. |

## Done (recent, newest first)

- [x] **Landscape shelf hard-snap fix** — landscape shelves were unpinned (only portrait was), so an up-nav focus-move renegotiated their height and hard-snapped the scroll. Pinned landscape too (`BrunoShelfMetrics.landscapeShelfRowHeight = 348`); sim-verified fit. Also capped poster prefetch to a screenful. INV-1 now covers both orientations.
- [x] **Selector-pill ("bubbles") highlight fix** — the accent focus ring was an `if`-inserted view that popped mid-scale; now always-present + opacity-animated so it cross-fades with scale/fill (`BrunoSelectorCard`).
- [x] **Home snappiness pass** (on `main`, branch `claude/tvos-perf-snappiness`). Four workstreams, all Bruno-owned/additive, build-verified:
  - **Streaming Home paint** — hero published the moment it lands (no more waiting on all ~18 shelves); shelves stream in top-down in plan order via a flush-consecutive reveal (load parallel, reveal shelf *i* only once 0..*i* settle → append-only, never shifts shown rows). Same for the explore tail. Generation-guarded. Soft fade+drift reveal (reduce-motion aware); hero auto-advance held until spine settles. `BrunoHomeViewModel`, `BrunoHomeView`, `BrunoHeroView`, `BrunoShelfView`.
  - **Disk-persisted Home payload + stale-while-revalidate** — `BrunoLibrarySnapshot` is `Codable`; new `BrunoHomeCache` (actor, off-main I/O, `try?`-tolerant) persists snapshot + hero superset pool + `.query` items, seed+userID-keyed. Relaunch paints instantly, then revalidates and reconciles in place by `shelf.id` (identity/focus survive). Live rows (`.resume`/`.nextUp`/`.recentlyAdded`) never cached.
  - **Bruno-owned poster prefetch** — `BrunoPosterPrefetcher` warms each row on appear via `.Swiftfin.posters` at the cell's exact width (`BrunoShelfMetrics`), low-priority, cancel-on-disappear. No stock edits. (spec §6 L159)
  - **Fragility guardrails** — `BrunoShelfMetrics` centralizes the 460 height + poster widths; `docs/BRUNO_PERF_INVARIANTS.md` documents INV-1..9 (what/why/break/safe-recipe + safe-to-touch surface); `// INV-n` anchors at each site. **Browse streaming deferred** into the Browse→Home redesign (shared-file collision); prefetch lands on the shared `BrunoShelfRow` row.
- [x] Browse vertical-scroll perf: fewer realized poster cells per row (browse only; Home untouched) — `BrunoCategoryShelves.swift` `shelfCap` 36→14, `BrunoShelfRow.swift` `.dataPrefix(40)`→`.dataPrefix(cards.count)`. Each cell is a focusable UIHostingController, so realizing fewer per row is the dominant scroll-cost lever; a shelf is a preview, "Show all" covers the rest. Declined (recorded so not re-attempted blindly): dropping `.posterShadow()` on browse (it's brand — README.md:189-193 — and browse-only drop is the drift the redesign fixes); removing `.hoverEffect(.highlight)` (focus-appearance risk, held for on-device measurement); grow-on-scroll sentinel (mockup treats browse as finite/fully-present; `LazyVStack` already virtualizes rows; would add off-brand pop-in). Branch `claude/strange-cray-165196`; not yet built (no TVVLCKit in worktree — owner builds `main` on device).
- [x] Dev auto-login to home server on fresh install (`b6fdacdb`, `BrunoDevAutoLogin.swift`)
- [x] Custom shelf: trailing Show-all card, ~36 items, hide loose movies (`d0d6e32f`)
- [x] Collections page: category row + per-category capped shelves + Show-all → grid (roadmap §3)
- [x] Genres page: core-category panel + keyword-mapped sub-genre shelves (`BrunoGenresView.swift`, roadmap §4)
- [x] Decades "Show all" → shelf-per-decade via `BrunoBoxSetShelvesView` (roadmap §4)
- [x] Hero auto-cycle (8s `Timer.publish`, pause-on-focus, cross-fade backdrop) (`BrunoHeroView.swift`, roadmap §1)
- [x] Real device install succeeded; session persists across relaunch on ad-hoc-signed build (`docs/STATUS.md`)
- [x] Headless real-library E2E + mock snapshot harnesses (`bruno-verify/`, `BrunoAutoSignIn.swift`)
- [x] App-wide rebrand: accent `#A1CCE0`, Oswald/Inter fonts, BRUNO wordmark
- [x] Toolchain restored to as-authored on Xcode 26.3 (compat shims reverted)

## Backlog / deferred (from PRODUCT_SPEC §8 + BRUNO_NOTES §Deferred)

- [ ] Direct hero-play (build `MediaPlayerItemProvider` → `.videoPlayer`; today routes to stock detail → Play)
- [ ] Localize Bruno UI strings via `L10n` (prototype is English-only; `hard_coded_display_string` disabled in Bruno views)
- [ ] Licensed Knockout font (Oswald is the brand stand-in)
- [ ] Seasonal BoxSet auto-surfacing (date-aware; Halloween in October, etc.)
- [ ] Formal XCTest target (today: `bruno-verify/` RNG checks + DEBUG self-check only)
- [ ] Open design questions from PRODUCT_SPEC §7 (Continue vs Up-Next merge, watched-dimming, studio card treatment, …)

---

## Spine vs tail (the product contract, condensed)

Home is a **stable spine** (shelves 2–10/11: Continue Watching → Up Next → New Releases → Director →
Genre → Series → Studio → Eras → Browse-by-Director → Collections) plus a **dynamic tail** of 5–6 seeded
"explore" shelves (+2 per scroll page, cap ~18). `seed = dayStamp()`, **Shuffle** re-rolls. `buildHome(seed)`
is pure given `(seed, librarySnapshot)`. Full taxonomy + generators: `PRODUCT_SPEC.md` §3–4.

## Guardrails (do not regress)

- **Additive, tvOS-only.** Bruno UI lives in `Swiftfin tvOS/Views/BrunoHomeView/` and `Shared/Objects/Bruno/`.
  iOS stays stock Swiftfin + rebrand. Don't touch player/nav/detail engine source.
- New files in the file-system-synchronized tvOS group → **no `.pbxproj` edits**. Non-Bruno edits stay
  DEBUG-gated and inert-by-default (see `SwiftfinApp.swift`).
- Never hardcode BoxSet/library IDs — discover groups dynamically (favorited BoxSets of BoxSets).
- **Before UX-polishing Home/browse shelves, read `docs/BRUNO_PERF_INVARIANTS.md`** (INV-1..9). The
  Home perf rests on non-obvious invariants (fixed row height, stable shelf ids, prefetch width ==
  cell width, seed-keyed/source-restricted cache); `// INV-n` anchors mark each site. Restyle freely —
  just keep those nine intact.
- No secrets in the repo. Live creds live only in gitignored `bruno_jellyfin.env`.
- Land finished work on **`main`** — the owner builds `main` in Xcode.
