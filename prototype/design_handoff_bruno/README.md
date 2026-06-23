# Handoff: Bruno — a "real-streamer" home experience for Jellyfin

## Overview
**Bruno** replaces off-the-shelf Apple-TV Jellyfin clients with a Netflix / Max / Apple TV+–grade
home screen for a personal, ~500-title cinephile library (movies **and** TV) served by a self-hosted
Jellyfin instance over LAN. It is a **hero/spotlight + endless vertical scroll of horizontal
"shelves"** experience — each shelf a different lens into the library (genre, year, director, studio,
curated set, randomized "explore" feeds) — leaning hard on the big backdrop art the owner has already
generated. It should feel **alive and explorable, never the same twice.**

- **Phase 1 (this design targets it):** Web proof-of-concept, laptop browser, React/HTML/CSS, hitting
  the real Jellyfin REST API.
- **Phase 2 (design for it now):** Native tvOS (SwiftUI / Swiftfin fork) driven by the focus engine —
  D-pad nav, focus scaling, 10-foot UI. Every layout decision here is focus-model-aware.

## About the Design Files
The files in this bundle are **design references created in HTML** — a streaming "Design Component"
prototype (`Bruno.dc.html`) showing the intended look, motion, and behavior. **They are not production
code to copy.** The task is to **recreate these designs in the target environment** (Phase 1: React +
plain CSS or CSS-modules/Tailwind, hitting Jellyfin; Phase 2: SwiftUI) using that platform's idioms —
focus engine on tvOS, semantic HTML + keyboard/remote handling on web. Treat the prototype as the
source of truth for **visual system, IA, shelf taxonomy, component anatomy, and interaction model.**

`Bruno.dc.html` is authored in a bespoke streaming-template runtime; **do not** try to reuse its
`<x-dc>` / `renderVals()` mechanics. Read it for markup structure, exact inline style values, and the
shelf-engine logic in its `<script>` class (data model, seeded RNG, `buildBase()`, `exploreGen()`,
`epsFor()`, `detailVM()` — all directly portable as plain JS/TS). **To *view* the running prototype,
open `Bruno_standalone.html`** (self-contained, double-click in any browser) — `Bruno.dc.html` opened
directly off disk shows raw `{{ … }}` placeholders because its runtime isn't loaded.

## Fidelity
**High-fidelity.** Final dark theme, colors, typography, spacing, card aspect ratios, focus/hover
states and motion are specified. Recreate pixel-faithfully, then swap placeholder gradient art for
real Jellyfin images (`Primary` posters + `Backdrop` 16:9). The Diplomacy brand palette/type is the
binding visual system (see **Design Tokens**).

---

## Information Architecture

```
Home  (hero/spotlight  +  vertical stack of shelves, infinite scroll)
 ├─ Shelf "See all"  →  Collection Grid  (banner + responsive card grid)
 ├─ Card (movie)     →  Item Detail (Movie)   →  Play
 ├─ Card (series)    →  Item Detail (Series)  →  Season tabs → Episode → Play
 └─ Tile (group/decade/director/studio) → Collection Grid
Top nav: Home · Movies · Series · Collections · Search · [Shuffle] · [TV Mode] · profile
```

Navigation depth is intentionally shallow: **Home → (Grid) → Detail → Play.** "Back" always returns to
Home in the prototype; in production, back should pop the actual nav stack (Grid↔Detail preserved).

---

## Screens / Views

### 1. Home
- **Purpose:** Lean-back discovery. Land, get pulled in by the spotlight, scroll shelves forever.
- **Layout:**
  - **Fixed top chrome** (height ~62px), transparent→opaque gradient (`linear-gradient(180deg,
    rgba(20,18,15,.96), rgba(20,18,15,0))`), `backdrop-filter: blur(2px)`, padding `14px 40px`.
    Left: **BRUNO** wordmark (Oswald 700, `letter-spacing:.16em`, uppercase) + accent dot. Nav items
    (Oswald 14px, `.12em`, uppercase; active `#F2F1F0`, idle `#9b958c`). Right: **Shuffle** + **TV
    Mode** buttons + circular avatar.
  - **Hero** (height `66vh`, min `540px`): full-bleed backdrop, **left-anchored** content max-width
    660px, bottom-aligned, padding `0 0 60px 40px`. Two scrims: a 90° left scrim and a 0° bottom
    scrim into the page bg. Contains: eyebrow (lens, accent, `.26em`), **title** (Oswald 600,
    `clamp(44px,5.6vw,82px)`, `line-height:.94`, uppercase), meta line (year · genre · runtime · ★),
    1-paragraph blurb, **Play** (filled `#F2F1F0` → `#14120f` text) + **More Info** (ghost, blurred)
    + 5 progress dots (active = accent) that switch the spotlight. Backdrop slowly Ken-Burns drifts
    (`@keyframes heroDrift`, scale 1.04→1.13 over 26s). Auto-rotates every 9s (pauses in TV Mode).
  - **Shelves region** pulled up `margin-top:-30px` over the hero base. Each **shelf** =
    header row (padding `24px 40px 12px`: eyebrow lens + H2 title Oswald 600 25px uppercase, and a
    right-aligned "See all →") above a horizontally-scrolling **row** (`display:flex; gap:16px;
    overflow-x:auto; padding:8px 40px 14px`; scrollbars hidden).
  - **Infinite scroll:** when within 900px of page bottom, append 2 more "explore" shelves (cap ~18).
    A pulsing "Loading more from your library…" row sits at the end.
- **Card variants used here:** backdrop card, director-portrait card, typographic tile (see Components).

### 2. Collection Grid (shelf / box-set expanded)
- **Purpose:** See every title in a lens (a genre, a decade, a director, "All Movies", "All Series").
- **Layout:** **Banner** (height 300px) = first item's backdrop + bottom scrim, with floating **‹ Back**
  (top-left, `84px/40px`), eyebrow lens, H1 title (Oswald 600 `clamp(40px,5vw,64px)`), and a count
  subtitle. Below: responsive grid `repeat(auto-fill, minmax(288px,1fr))`, gap 18px, padding
  `30px 40px 80px`. Cards are 16:9 backdrop cards (poster cards acceptable for person/curated lenses).

### 3. Item Detail — Movie
- **Purpose:** Decide and play. Full Jellyfin metadata.
- **Layout:** **Detail hero** (height `74vh`, min 560px), same scrim system as Home hero + drift.
  Floating **‹ Back**. Content (max-width 740px, bottom-anchored):
  - Eyebrow = "Directed by {director}" (accent).
  - **Title** (Oswald 600 `clamp(46px,6vw,88px)`).
  - **Tagline** (italic, `#cfc9bf`) — movies usually omit; series show it.
  - **Meta chip row:** content-rating pill (bordered), year, runtime, **★ community rating** (accent,
    bold), **● critic %** (small red dot), "Ends at H:MM AM/PM" (computed `now + runtime`).
  - **Overview** paragraph.
  - **External-ID chips:** IMDb · TheMovieDb (bordered, subtle).
  - **Actions:** **▶ Play** (filled) · **Trailer** (ghost) · **✓** mark-watched · **♡** favorite (icon
    buttons 50×50, blurred ghost).
  - **Below the fold** (padding `0 40px 80px`):
    - **Two metadata panels** side-by-side (`flex:1 1 380px` each, bordered `rgba(242,241,240,.1)`,
      radius 10, bg `rgba(242,241,240,.025)`): **Left** = key/value rows (Genres, Director, Studios,
      [Network], [Status]) with Oswald label left + value right. **Right** = **media info** rows
      (video `▦ 1080p HEVC SDR` etc., audio `♪ English · AAC 5.1`, subtitles `⊟ Subtitles · English
      (SRT)`).
    - **Cast & Crew** carousel (only when known): horizontally-scrolling 108px columns — 84px circular
      avatar (gradient + initials placeholder; swap for Jellyfin `People` `Primary` image), bold name,
      muted role.
    - **Related rows:** "More from {director}" + "You Might Also Like" (backdrop cards).

### 4. Item Detail — Series  (TV)
- Same hero/meta/panels/cast/related structure as Movie, **plus**:
  - Eyebrow = "Series"; **tagline** shown; meta uses **year-range** ("2022 – 2025") and **"N Seasons"**
    instead of runtime; **no** critic %/ends-at; left panel shows **Network** + **Status**
    (Ended/Continuing) instead of Director; Play label = "Resume S{n} E{n}".
  - **Episodes block:** "EPISODES" H2 followed by **Season tab buttons** (active = accent bg / dark
    text; idle = ghost). Below, a **responsive grid of episode cards**
    (`repeat(auto-fill, minmax(320px,1fr))`, gap `26px 22px`): a 16:9 thumbnail (backdrop + center
    **▶** play disc + top-right **✓** watched badge + bottom progress bar when in-progress), then
    "{n}. {Title}", a meta line ("44m · ★ 7.8 · Ends at 7:14 PM"), and a 3-line-clamped overview.
  - Related row = "More Like This" (series cards).

### tvOS Focus Demo (built into Home)
Toggle **TV Mode** in the chrome to switch the web PoC into a **10-foot focus model** that mirrors the
Apple TV focus engine: a roving focus index over `[hero] → shelf 0 → shelf 1 …`; **Arrow keys** move
focus (Left/Right within a row, Up/Down between rows), **Enter** activates, **Esc** exits. The focused
card **scales to 1.07** with a **3px accent focus ring** + lifted shadow; the row scrolls horizontally
and the page scrolls vertically to keep focus framed (~42% from top). A bottom hint bar shows the
controls. Hero auto-rotation pauses in TV Mode. *(On real tvOS, this maps 1:1 to `focusable` +
`.focused()` scale/shadow and the native focus engine — no manual key handling.)*

---

## Interactions & Behavior
- **Spotlight rotation:** auto-advance every 9s; dots jump directly; pauses under TV Mode.
- **Card hover (pointer):** `transform: scale(1.055)` + 2px accent ring + `0 18px 38px rgba(0,0,0,.55)`,
  transition `.24s cubic-bezier(.2,.7,.2,1)`. **Focus (TV Mode):** scale 1.07 + 3px ring.
- **Shuffle:** re-seeds the home (new spotlight pool + freshly generated dynamic shelves), scroll to top.
- **Season tabs:** swap the episode grid for that season's episodes.
- **Navigation:** card → detail (scroll to top); "See all" / tile → grid; Back → previous screen.
- **Infinite scroll:** append explore shelves near page bottom.
- **Continue Watching / Up Next / episode progress** render a bottom progress bar (accent) from Jellyfin
  `UserData.PlayedPercentage` / `PlaybackPositionTicks`.
- **Reduced motion:** disable hero drift + entrance transitions under `prefers-reduced-motion`.

## State Management
- `screen`: `home | grid | detail` (production: real router/stack).
- `seed` (int): drives all seeded randomness; bump on **Shuffle** and once per **session/day** (see
  Dynamic Shelf Engine). `heroIdx`: current spotlight. `detailItem` + `detailSeason`: current detail.
- `tvMode` + `focRow`/`focCol`: focus engine. `gridShelf`: current grid payload.
- **Data fetching:** all shelves/grids/detail come from Jellyfin (see API Mapping). Cache collection
  membership and images aggressively (LAN, but art is large); paginate rows (fetch ~20/row, lazy-load
  on horizontal scroll).

---

## Design Tokens

### Color (Diplomacy palette → Bruno dark theme)
| Token | Value | Use |
|---|---|---|
| `--page` | `#14120f` | App background (deepened warm umber) |
| `--surface` | `#1c1a16` | Card base before art loads |
| `--diplomacy-dark` | `#302D26` | Brand near-black umber |
| `--diplomacy-brown` | `#4E433D` | Elevated warm surface / portrait cards |
| `--fg` | `#F2F1F0` | Primary text (brand Light) |
| `--fg-muted` | `#cfc9bf` / `#d4cec4` | Body / blurbs |
| `--fg-subtle` | `#9b958c` / `#b7b1a7` | Meta, idle nav |
| `--accent` | `#A1CCE0` | **Focus ring, progress, ★, active states, dots** (Apolla sky) |
| `--accent-alt` | `#849396` | Diplomacy Blue (alt accent option) |
| `--sand` | `#D9D7C2` | Tile text / warm highlights |
| `--critic` | `#C44` | Critic-score dot |
| Director name-card bg | `linear-gradient(160deg,#3c4267,#1d2034)` | Indigo portrait backdrop |
| Scrim (card) | `linear-gradient(0deg, rgba(8,7,6,.86), rgba(8,7,6,.2) 46%, transparent 72%)` | Title legibility |
| Scrim (hero L) | `linear-gradient(90deg, rgba(20,18,15,.97) 0%, …0% at 78%)` | Hero text legibility |

Backdrop placeholder art = duotone `linear-gradient(150deg, c0, c1)` from a 12-pair cinematic palette,
chosen by `hash(title) % 12`, layered with a top-right highlight + bottom-left vignette radial. In
production these are replaced by real Jellyfin `Backdrop`/`Primary` images; **keep the scrims**.

### Typography
- **Display:** `Oswald` (700/600/500/400), uppercase, `letter-spacing` ~`.02–.26em` by size — this is
  the **Knockout** brand stand-in. (Production tvOS: use licensed Knockout if available; else Oswald.)
- **Body:** `Inter` (400/500/600).
- Scale (px): hero title `clamp(44,5.6vw,82)` · detail title `clamp(46,6vw,88)` · grid H1
  `clamp(40,5vw,64)` · shelf H2 `25` · section H2 `23` · card title `15–16` · body `15` · meta `11–14`
  · eyebrow/label `10–13` (`.16–.26em`).

### Spacing / Radius / Shadow
- Page gutter **40px**; row gap **16px**; grid gap **18px**.
- Radius: cards **8px**, portrait/tiles **10px**, pills **4–6px**, avatars **50%**.
- Card shadow idle `0 6px 18px rgba(0,0,0,.4)`; hover `0 18px 38px rgba(0,0,0,.55)` + ring; focus
  `0 0 0 3px var(--accent), 0 20px 44px rgba(0,0,0,.6)`.
- Motion: cards `.24s cubic-bezier(.2,.7,.2,1)`; hero drift 26s; detail drift 30s.

### Card aspect ratios & sizes
| Card | Size (web) | Ratio | Used for |
|---|---|---|---|
| Backdrop card | 300×169 | 16:9 | movies, series, studios, continue/up-next, explore |
| Episode card | min 320 wide | 16:9 | episode thumbnails |
| Director-portrait card | 170×248 | ~2:3 | auteurs (indigo name-card + initials/headshot) |
| Typographic tile | 232×150 | ~3:2 | group + decade tiles (big Oswald label) |
| Grid card | minmax(288) | 16:9 | collection grids |

---

## Component Inventory
1. **Top chrome / nav bar** — wordmark, nav, Shuffle, TV-Mode, avatar.
2. **Hero / spotlight** — rotating backdrop feature with dots.
3. **Shelf** — header (eyebrow + title + See-all) over a horizontal carousel.
4. **Backdrop card** — 16:9 art + bottom scrim + title/meta; optional **badge** (Series / Up Next),
   optional **progress bar**, optional **studio-logo centered** treatment.
5. **Director-portrait card** — indigo name-card, circular avatar (Jellyfin `People` image / initials),
   name + film count.
6. **Typographic tile** — solid brand-duotone, big Oswald label (decade "1970s", group "Directors").
7. **Episode card** — 16:9 thumb + play disc + watched/progress, number-title, meta, 3-line overview.
8. **Metadata panel** + **media-info panel** (detail).
9. **Cast & Crew carousel.**
10. **Season tab bar.**
11. **Collection grid.**
12. **Focus ring / TV-mode hint bar.**

---

## Assets
- **No real images in the prototype** — all art is procedural gradient placeholder. Production pulls
  **real art from Jellyfin**: movie/series `Primary` (poster), `Backdrop` (16:9), `Logo` (title art),
  person `Primary` (cast headshots), studio `Primary`/`Backdrop`. The owner has authored bespoke art
  for every tile (typographic group/decade tiles, director headshot + indigo name-card backdrops, real
  studio-logo backdrops, de-duped posters + 16:9 backdrops) — request the highest-res image and let the
  scrims do the legibility work.
- **Brand assets** (Diplomacy logo, color file) live in the design-system project; use the existing
  brand system in the target codebase. Icons in the prototype are unicode glyphs — replace with the
  app's icon set (SF Symbols on tvOS).

## Files in this bundle
- **`Bruno_standalone.html`** — ▶ **Open this one to view the prototype.** A single self-contained file
  (runtime inlined); just double-click it in any browser, online or offline. Contains the full
  experience: Home, Grid, Movie Detail, Series Detail w/ seasons+episodes, TV-Mode focus demo, the
  dynamic shelf engine, and a sample movie+TV dataset.
- `Bruno.dc.html` — **source reference for the coding agent** (readable markup + the shelf-engine logic
  class). It is a streaming "Design Component" that needs its `support.js` runtime to render, so it will
  show raw `{{ … }}` placeholders if opened directly off disk — that's expected; read it as source, view
  `Bruno_standalone.html` to see it run.
- `PRODUCT_SPEC.md` — PRD, full shelf taxonomy, **Dynamic Shelf Engine** rules, **Jellyfin API mapping**,
  open questions, and web-PoC-vs-native phasing.
- `README.md` — this file.
