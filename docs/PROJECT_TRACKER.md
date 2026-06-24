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

_Last synced: 2026-06-23 (initial creation). Update this date on every edit._

---

## Now / next (the active push: tvOS IA + browse polish)

| St | Item | Where | Notes / blocker |
|----|------|-------|-----------------|
| [ ] | Tab IA reorder → **Home · Movies · TV Shows · Collections · Kids · Search · Settings** | `Shared/Coordinators/Tabs/MainTabView.swift`, `TabItem.swift` | Decided 2026-06-23. Replace `Media`→`Collections`, drop redundant Media. |
| [!] | `TabItem.kids` → existing Jellyfin kids library/folder | `TabItem.swift`, `BrunoKidsView.swift` | **BLOCKED:** need exact Kids library name(s)/id(s) on the server. |
| [~] | System Top Shelf extension (dynamic previews) | `BrunoTopShelf/`, `BrunoTopShelfCredentials.swift` | Groundwork shipped; owner must create the target + App Group + signing. See `docs/TOP_SHELF_SETUP.md`. |
| [ ] | Night-mode / settings surface | (TBD) | Called out as outstanding in the latest handoff. Scope undefined. |
| [ ] | On-device shelf check (focus feel, scroll-jump landing) | Home / Collections / Genres | Category-row scroll-jump + hero focus feel want a real Apple TV pass. |

## Done (recent, newest first)

- [x] Directors/Studios "Show all" lists only the collections, not their movies (`d7de39ef`)
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
- No secrets in the repo. Live creds live only in gitignored `bruno_jellyfin.env`.
- Land finished work on **`main`** — the owner builds `main` in Xcode.
