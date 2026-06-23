# Bruno — Build Plan

## Goal
A "real streamer" home for a ~500-movie curated Jellyfin library: hero spotlight, then endless
vertical scroll of horizontal shelves — a genre, a year, a director, a studio, a curated set,
and randomized **explore** feeds — all using big backdrop art. Feels alive; never the same twice.

## Why web-PoC-first
- Runs in a laptop browser: `git clone` + `npm run dev`. No Xcode / Apple TV / code-signing.
- Iterates in seconds; validates the UX against the **real library + real art** via the Jellyfin REST API.
- De-risks the design before paying for the native tvOS port (Swiftfin fork).

## Pipeline
1. **Design thread** → product spec + HTML mockups (`docs/DESIGN-PROMPT.md`).
2. **Execution handoff** (multi-agent) → builds out this web PoC against the spec, pushes to git.
3. **Validate / iterate** in the browser.
4. **Native port** → SwiftUI / Swiftfin fork for Apple TV, reusing the validated design + shelf logic.

## Architecture (web PoC)
- Vite + React. Dev proxy `/jf` → Jellyfin (CORS workaround), config via `.env`.
- `src/api/jellyfin.js` — REST client. Jellyfin endpoints in play:
  - Group tiles / favorites: `Items?IncludeItemTypes=BoxSet&IsFavorite=true`
  - Collection members: `Items?ParentId={id}`
  - Recent: `Items?SortBy=DateCreated&SortOrder=Descending`
  - Random/explore: `Items?SortBy=Random`
  - By genre/year/studio/person: `Items?Genres=` / `Years=` / `StudioIds=` / `PersonIds=`
  - Art: `Items/{id}/Images/Backdrop` and `/Primary`
- Components to build: hero/spotlight, carousel (`Shelf`), card variants (backdrop, poster,
  typographic tile, director portrait, studio logo), collection grid, item detail page.

## The "shelf engine" (dynamic home)
Generate a fresh, explorable home each session from rules, e.g.:
- Rotating spotlight (random high-rated unwatched)
- "Spotlight on {random director}"
- "{random year} in film"
- "If you like {random genre}"
- "From the {studio} vault"
- "Acclaimed & unwatched"
- Continue Watching / Recently Added (fixed)
Seeded random so a session is stable but a refresh reshuffles.

## Open items
- **Git host** for the repo (GitHub / Gitea on the NAS / GitLab?) — needed to push.
- Player: web PoC can use the Jellyfin stream URL in a `<video>`; native uses AVPlayer/VLCKit (TBD).
- Decide first locked shelf set vs. fully dynamic.
