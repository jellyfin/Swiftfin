# Handoff — Studios grid polish (cinematic look + HQ logos + focus carousel)

> Status: **spec only, not implemented.** Three owner asks for the **Studios "Show all" grid**.
> Author handed off after repeatedly missing on a Hollywood-sign backdrop (4 attempts) — that
> approach was **reverted**; do NOT reintroduce a single full-bleed Hollywood photo behind the grid.
> See [[bruno-studio-backdrop-and-simnav]] for what went wrong.

## Current state (merged baseline)

- Studios "Show all" renders via **`BrunoBoxSetGridView`** (`Swiftfin tvOS/Views/BrunoHomeView/BrunoBoxSetGridView.swift`),
  a `CollectionVGrid` of **landscape** `PosterButton` cards. Studios route to it with
  `posterType: .landscape` from `BrunoCategoryShelves.routeToShowAll` (the `.grid` branch,
  `isStudios` check).
- Cards show the studio's **Primary** (portrait, used by the inline shelf) / **Thumb** (16:9, used
  by the landscape grid) image. Those are generated server-side by the builder script
  `~/Documents/Claude/MovieCollection/Build-Jellyfin-Collections.command`:
  - `make_logo_poster` (portrait) + `make_logo_thumb` (16:9) composite the studio's **transparent
    Logo** onto a branded card. If a studio has **no transparent Logo**, the builder draws a clean
    **name card** (`make_poster`/`make_backdrop`) — never a logo-intro screenshot.
  - Each studio collection's **Overview** is set from `studio_blurbs.json` (92 studios) — shows on
    the studio detail page (`CinematicScrollView` → `OverviewView`).
- The studio **detail page** (the look the owner loves — see the 20th Century Fox screenshots) is
  the stock `Swiftfin tvOS/Views/ItemView/ScrollViews/CinematicScrollView.swift`: full-bleed
  backdrop, logo, title, ✓/♥ buttons, then a "Movies" poster shelf.

## Ask 1 — Make the main Studios grid look like the detail page

The owner wants the grid to feel as polished/cinematic as the **detail page**, NOT a single
Hollywood photo behind a grid (that was rejected). **Confirm the exact intent with the owner**, but
the most likely reading is a **focused-studio hero/preview** at the top of the grid that updates as
focus moves, mirroring `CinematicScrollView`'s treatment for the *currently focused* studio:

- A top hero region (~40% height) showing the **focused studio's** logo (big), name, and blurb,
  over a dark cinematic backdrop, with the grid of studio cards below.
- As tvOS focus moves between studio cards, the hero updates to that studio (use
  `@FocusState`/`focusedValue` or `.onChange` of a focused-studio binding).
- Reuse the existing cinematic vocabulary: `BlurView(style:.dark)` + gradient mask
  (`CinematicScrollView.swift:84-96`), brand tokens (`Color.bruno.*`, `Font+Bruno`).

Technical facts (verified by bruno-expert + swift-xcode-expert):
- `CollectionVGrid` is **already transparent** (the package sets `collectionView.backgroundColor =
  nil` and the hosting cell bg to `nil`) — a `ZStack` sibling backdrop shows through. Do NOT touch
  `UIAppearance` or `.scrollContentBackground`.
- Lay any backdrop as a **sibling ZStack layer** (like `BrunoAmbientBackground`), `ignoresSafeArea()`
  + `allowsHitTesting(false)`, with the grid topmost. Use `.safeAreaInset(edge:.top){ Color.clear
  .frame(height:) }` on the grid to reveal a top hero band while rows scroll up over it.
- Keep the perf invariant: backdrop is a sibling, never a ScrollView `.background` (INV-6).

## Ask 2 — High-quality studio logo art

Current logos come from Jellyfin's per-studio images, which are often low-res or logo-intro
screenshots. Get **HQ transparent logos** (PNG with alpha), e.g. from **TMDB** company images
(`/company/{id}/images` → `logos[]`, choose the highest-res PNG; TMDB IDs resolvable by company
name). Pipeline (builder-script side):
- For each studio, resolve its TMDB company id, download the best transparent PNG logo, upload it as
  the studio's **Logo** image in Jellyfin (`POST /Items/{studioId}/Images/Logo`), then the existing
  `make_logo_poster`/`make_logo_thumb` composite uses it.
- Keep the **name-card fallback** for studios with no good logo.
- Note: needs a TMDB API key; the builder currently uses **no** TMDB — this adds that dependency.
- Trim transparent margins so logos are visually consistent in size on the card.

## Ask 3 — Focused-studio card art carousel (cycle every 2s)

When a studio card is **focused/selected**, swap its art from the static logo to a **contained**
(aspect-fit, not fill) carousel cycling through that studio's movie posters/art, advancing **every 2
seconds**; revert to the logo on unfocus.

Design:
- Build a custom cell `BrunoStudioCard` (replace the plain `PosterButton` for the studios grid).
  Read focus via `@Environment(\.isFocused)` (the cell is inside a `.card` button) or a `@FocusState`.
- On focus: lazily fetch the studio's child movie image sources (one `getItems?ParentId={studioId}`
  with `ImageTags`/primary), cache them; start a `Timer`/`TimelineView` advancing an index every 2s;
  render the current movie image with `contentMode: .fit` (contained) cross-fading between frames.
- On unfocus/disappear: stop the timer, reset to the logo.
- Performance: only the **focused** card runs a timer (one at a time). Prefetch the focused studio's
  first few images. Respect `accessibilityReduceMotion` (no auto-advance / instant).
- This is studio-grid-specific; gate it so Boxed Sets / Directors keep their current cards.

## Pitfalls / guardrails
- Do **not** re-add a single full-bleed Hollywood photo behind the grid (rejected; reverted).
- tvOS **sim navigation via osascript is unreliable** — verify on a real Apple TV or have the owner
  check; don't burn cycles blind-driving the sim.
- Builder script changes need an **owner run** (it writes to the live Jellyfin server; hardcoded token).
- Additive, tvOS-only, no `.pbxproj` edits. Asset-catalog imagesets can be added folder-only.

## Files
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoBoxSetGridView.swift` — grid + cell (Ask 1, 3)
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoCategoryShelves.swift` — Studios route (`routeToShowAll`)
- `Swiftfin tvOS/Views/ItemView/ScrollViews/CinematicScrollView.swift` — the look to mirror (Ask 1)
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoAmbientBackground.swift` — sibling-backdrop pattern
- `~/Documents/Claude/MovieCollection/Build-Jellyfin-Collections.command` — logos/blurbs (Ask 2)
- `~/Documents/Claude/MovieCollection/studio_blurbs.json` — studio overviews (done)
