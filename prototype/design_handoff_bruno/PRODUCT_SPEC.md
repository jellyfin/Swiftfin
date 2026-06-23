# Bruno — Product Spec (PRD) + Dynamic Shelf Engine + Jellyfin API Mapping

> Companion to `README.md` and the `Bruno.dc.html` prototype. This is the implementation contract for
> the coding agent. Quantities (item counts, thresholds) are defaults — tune against the real library.

---

## 1. North star
A home screen that makes a 500-title personal library feel **infinite, curated, and alive**. The owner
already built the curation (7 group BoxSets, ~130 child collections, rich art). Bruno's job is to
**surface that curation as motion-design-grade shelves**, mix in **seeded randomized "explore" feeds**
so it's *never the same twice*, and stay **fully focus-navigable** for a future tvOS port. Every screen
must read at 10 feet: large targets, bold focus state, horizontal-carousel-first.

Success = the owner opens Bruno instead of the stock Apple-TV client, and *keeps scrolling*.

---

## 2. Home information architecture
Vertical stack, top-to-bottom:

1. **Hero / rotating spotlight** (1 of N seeded features).
2. **Continue Watching** (resume in-progress movies *and* episodes).
3. **Up Next** (next unwatched episode of in-progress series).
4. **New Releases** (recently added).
5. **Spotlight on {director}** (seeded auteur).
6. **{Genre}** ("If You Like" a seeded genre).
7. **Series in the Library** (browse TV).
8. **From the {studio} Vault** (seeded studio).
9. **Eras** (decade typographic tiles → grids).
10. **Browse by Director** (auteur portrait cards → grids).
11. **5–6 seeded "explore" shelves**, then **+2 per infinite-scroll page** (cap ~18 total).

Items 2–10 are the **stable spine** (deterministic structure, contents may rotate by seed). Item 11 is
the **dynamic tail**. This matches the owner's requested priority: *Continue Watching → New Releases →
Director → Genre → Studio → then random seeds*, with **mostly-stable + infinite fresh shelves on scroll.**

---

## 3. Full shelf taxonomy
Each shelf: **lens** (eyebrow), **title**, **card type**, **source**, **fixed vs dynamic**, **count**,
**sort**. `seed` = current session seed (see §5). `rng(seed*k)` = seeded PRNG (mulberry32 in prototype).

| # | Shelf | Lens | Card | Source (Jellyfin) | Type | Count | Sort |
|---|---|---|---|---|---|---|---|
| 1 | Hero spotlight | "Spotlight" | hero | Items, `CommunityRating ≥ 8.2`, pick 5 by `rng(seed)` | rotating | 5 | seeded shuffle |
| 2 | Continue Watching | "Pick up where you left off" | backdrop + progress | `/Users/{id}/Items/Resume` (movies+episodes) | dynamic | ≤12 | last-played desc |
| 3 | Up Next | "Next episode" | backdrop + badge + progress | `/Shows/NextUp?userId=` | dynamic | ≤12 | next-up order |
| 4 | New Releases | "Just added" | backdrop | Items `SortBy=DateCreated&SortOrder=Descending` | dynamic | 12 | DateCreated desc |
| 5 | Spotlight on {director} | "Director Spotlight" | backdrop | People(Director) → their Items; director = seeded pick (≥3 films) | rotating | all + fillers | year/seeded |
| 6 | {Genre} | "If You Like" | backdrop | Items `Genres={g}`; g = seeded genre (≥3 titles) | rotating | all | seeded shuffle |
| 7 | Series in the Library | "Television" | backdrop + "Series" badge | Items `IncludeItemTypes=Series` | fixed | all | seeded/A–Z |
| 8 | From the {studio} Vault | "From the Vault" | backdrop (or studio-logo card) | Items `Studios={s}`; s = seeded (≥2) | rotating | all | seeded shuffle |
| 9 | Eras | "Browse by Decade" | typographic tile | Decade child BoxSets (or `Years=` buckets) | fixed | 8 (1950s–2020s) | chronological |
| 10 | Browse by Director | "Auteurs" | portrait | People with role Director, ≥3 films | fixed | 12 | film-count desc |
| 11 | Browse the Library | "Collections" | typographic tile | 7 top-level group BoxSets | fixed | 7 | curated order |
| E | **Explore generators** (the dynamic tail — see §4) | varies | backdrop / portrait / tile | seeded per slot | dynamic | 10 | seeded |

**Group → child collection mapping** (the owner's existing BoxSet structure — drive shelves/grids from
these BoxSets first, fall back to computed queries):
`New Releases`, `Directors`(37 auteurs), `Decades`(1950s&Earlier…2020s), `Genres`(fine combos + broad),
`Studios`(28, e.g. A24/Warner/Pixar), `Curated`(Film School Classics, Asian Cinema, Oscar Buzz,
Critically Acclaimed), `Seasonal`(Christmas, Halloween, 4th of July). Surface **Seasonal** contextually
(date-aware) and **Curated** as recurring explore lenses.

---

## 4. Dynamic Shelf Engine (the "never the same twice" core)

### Generators
A registry of **explore generators**, each `(seed) → Shelf`. The prototype implements these in
`exploreGen(key, rng)`; port directly:

| key | Shelf produced | Logic |
|---|---|---|
| `year` | "{year} & Around" | pick a `ProductionYear` present in library by seed; items = titles within ±1–2 yrs |
| `acclaimed` | "Acclaimed & Unwatched" | `CommunityRating ≥ 8.1` **AND** `UserData.Played = false`, seeded shuffle |
| `spotlight` | "Spotlight on {director}" | seeded director (≥2 films) → their filmography |
| `genre` | "If You Like {genre}" | seeded genre → its titles, seeded shuffle |
| `studio` | "From the {studio} Vault" | seeded studio (≥2) → its titles |
| `decade` | "Hidden in the {decade}s" | seeded decade → its titles, seeded shuffle |
| `critics` | "Critics' Highest Rated" | top 10 by `CommunityRating` (and/or `CriticRating`) |
| `world` | "Around the World" | non-domestic studios / foreign-language titles |
| `curated` | "{Curated set}" | a random **Curated** child BoxSet (Asian Cinema, Oscar Buzz, …) |
| `seasonal` | "{Holiday} Picks" | the **Seasonal** BoxSet matching current date window |

### Composition rules
- **Stable spine (shelves 2–11):** structure fixed; *contents* reseed when the session seed changes.
- **Dynamic tail:** on first home build, fill **5–6** explore slots = `shuffle(generatorKeys, rng(seed))`
  picked without repeats. **Infinite scroll** appends **2 more** per page from the generator pool using
  `rng(seed*131 + slotIndex)`, cap ~**18** shelves, then a graceful "end of library" state.
- **De-dupe:** within a single home render, avoid showing the same title in >2 shelves and avoid two
  adjacent shelves of the same generator key.
- **Per-row pagination:** request ~20 items/row; lazy-load more on horizontal scroll.

### Seeding & freshness (owner chose: *mostly stable + 5–6 explore + fresh on scroll*)
- `seed = dayStamp()` → **stable within a session/day** (recognizable, not chaotic).
- **Shuffle button** → `seed = random()` → full re-roll (new spotlight pool + new explore tail), scroll
  to top. This is the "surprise me" lever.
- Hero pool, every shelf's seeded pick, and the explore tail all derive from `seed` so one number fully
  determines a home. (Persist last seed in `localStorage` so reloads are consistent; new day → new seed.)

### Determinism contract
`buildHome(seed)` must be **pure** given `(seed, librarySnapshot)` — same seed ⇒ same home. This makes
the experience reproducible, testable, and trivially portable to SwiftUI.

---

## 5. Navigation model
`Home → [Shelf "See all" → Collection Grid] → Item Detail → Play`
- Card click/Enter → **Detail** (movie or series).
- Shelf "See all" / tile / portrait → **Grid** (the lens expanded; back returns to Home with scroll
  position restored).
- Series Detail → **Season tab** → **Episode** (Play) — episodes are the leaf playable for series.
- **Back** pops the stack. **Play** hands off to the Jellyfin player (web: `PlaybackInfo` → HLS/direct;
  tvOS: native player) and reports progress to `/Sessions/Playing`.

---

## 6. Jellyfin REST API Mapping
Base: `{server}/...`, auth via `X-Emby-Token` (API key / user token). Key endpoints:

**Library & shelves**
- `GET /Users/{userId}/Items?ParentId={collectionId}` — members of a BoxSet (group or child).
- `GET /Users/{userId}/Items?IncludeItemTypes=Movie&Recursive=true&SortBy=DateCreated&SortOrder=Descending&Limit=12` — New Releases.
- Filters used across shelves: `Genres=`, `Studios=`, `Years=`, `PersonIds=`/`Person=` (+`PersonTypes=Director`),
  `Filters=IsUnplayed`, `MinCommunityRating=`, `SortBy=Random|CommunityRating|ProductionYear|SortName`.
- `GET /Items?IncludeItemTypes=BoxSet&Recursive=true` — discover the 7 groups + ~130 child collections;
  a BoxSet whose children are BoxSets = a "group".
- `GET /Genres`, `GET /Studios`, `GET /Persons?PersonTypes=Director` — taxonomy for lenses.

**Continue / Up Next / progress**
- `GET /Users/{userId}/Items/Resume?Limit=12&MediaTypes=Video` — Continue Watching (movies+episodes).
- `GET /Shows/NextUp?userId={userId}&Limit=12` — Up Next episodes.
- Progress per item: `UserData.PlayedPercentage`, `UserData.PlaybackPositionTicks`, `UserData.Played`,
  `UserData.IsFavorite` (request with `Fields=UserData` or via `/Users/{userId}/Items`).

**TV structure (seasons/episodes)**
- Series item: `IncludeItemTypes=Series`. Seasons: `GET /Shows/{seriesId}/Seasons?userId=`.
- Episodes: `GET /Shows/{seriesId}/Episodes?seasonId={seasonId}&userId=&Fields=Overview,MediaSources`.
- Episode fields used: `IndexNumber`, `Name`, `RunTimeTicks`, `CommunityRating`, `Overview`,
  `UserData.Played/PlayedPercentage`, `ImageTags.Primary` (thumb).

**Detail metadata (movie or series)**
- `GET /Users/{userId}/Items/{itemId}?Fields=Overview,Genres,Studios,People,Taglines,ProviderIds,MediaStreams,MediaSources,ProductionYear,OfficialRating,CommunityRating,CriticRating,EndDate,Status`.
  - Title art: `ImageTags.Logo`; backdrop: `BackdropImageTags`; poster: `ImageTags.Primary`.
  - **Cast & crew:** `People[]` (`Name`, `Role`, `Type`, `PrimaryImageTag` → person image).
  - **Tagline:** `Taglines[0]`. **Content rating:** `OfficialRating`. **Community:** `CommunityRating`.
    **Critic:** `CriticRating`. **Status** (series): `Status` (Continuing/Ended) + `ProductionYear`/`EndDate`.
  - **Media info panel:** from `MediaStreams[]` — video `{Height}p {Codec} {VideoRange}`, audio
    `{Language} · {Codec} {ChannelLayout}`, subtitle streams (`Language`, `Codec`). Build the
    `1080p HEVC SDR` / `English · AAC 5.1` / `Subtitles · English (SRT)` strings from these.
  - **External IDs:** `ProviderIds` → `Imdb`, `Tmdb` (link out / display chips).
  - **"Ends at":** `now + RunTimeTicks` (episode/movie) formatted local time.

**Images**
- `GET /Items/{id}/Images/{Backdrop|Primary|Logo}?maxWidth=...&tag={imageTag}`. Prefer `Backdrop` for
  16:9 cards, `Primary` for poster/portrait, `Logo` for hero title art. Person images:
  `GET /Items/{personId}/Images/Primary`. Cache by `{id}-{tag}`; preload visible + next-in-row.

**Playback**
- `GET /Items/{id}/PlaybackInfo` (or `/Users/{userId}/Items/{id}/PlaybackInfo`) → stream URL
  (DirectPlay/HLS). Report with `POST /Sessions/Playing`, `/Sessions/Playing/Progress`, `/Stopped`.

---

## 7. Open design questions
1. **Continue Watching vs Up Next** — merge into one row, or keep separate (current)? Behavior when a
   movie is resumable *and* an episode is up-next for the same evening.
2. **Seasonal surfacing** — auto-inject the date-matching Seasonal BoxSet as a high shelf in-window
   (e.g. Halloween in October), and/or as a themed hero? How aggressive?
3. **Spotlight content** — films only (current), or also feature a series/season as a hero?
4. **Studio shelf treatment** — backdrop cards of the studio's films, *or* studio-logo cards that drill
   into the studio grid (both designed)? Which is primary on home?
5. **"Watched" visibility** — dim/checkmark already-seen titles on cards, or keep them clean?
6. **Search** — scope (title/person/genre), and voice on tvOS. Out of scope for PoC?
7. **Multi-user** — single owner profile assumed; if household profiles, Continue/Up-Next/Favorite all
   become per-user (`userId` already threaded through every call).
8. **Randomness comfort** — is day-stable + Shuffle the right cadence, or add a subtle auto-reshuffle on
   each cold launch?

---

## 8. Phasing

### Phase 1 — Web PoC (in scope now)
- React + CSS; the exact visual system, IA, all card types, hero, shelves, grid, **both** detail
  layouts (movie + series w/ seasons/episodes), full Jellyfin metadata panels.
- Real Jellyfin API for every shelf/grid/detail; real art; real progress/favorite.
- Dynamic shelf engine with day-seed + Shuffle + infinite scroll.
- **Pointer + keyboard** nav; **TV Mode** demonstrating the focus model (arrow/Enter/Esc, focus ring,
  focus-follow scroll) to validate the 10-foot design before the native build.
- Playback via Jellyfin web player handoff.

### Phase 2 — Native tvOS (design-validated here, deferred build)
- SwiftUI / Swiftfin fork driven by the **focus engine** — replace manual key handling with
  `focusable()` + `.focused()` scale/shadow; `LazyHStack`/`LazyVStack` carousels; native player.
- Port `buildHome(seed)` / generators / `detailVM` logic verbatim (pure functions).
- Map tokens to SwiftUI (colors, Oswald/Knockout, the 8/10/16/40 spacing rhythm, focus ring).
- SF Symbols for icons; native Top Shelf extension could reuse the spotlight pool.
- **Deferred:** search, multi-user profiles, settings, Seasonal automation, Top Shelf — unless promoted.
