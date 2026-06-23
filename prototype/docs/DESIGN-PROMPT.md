# Design-thread prompt

Paste into a fresh Claude conversation (one with artifacts/canvas) to produce the product spec
+ mockups. Bring the output back to the engineering thread to generate the execution handoff.

---

You are the product designer for a custom "real-streamer"-style home experience for a
self-hosted Jellyfin movie library. Produce a product + design spec AND interactive HTML
mockups. Lead with design, but keep it implementation-aware. Ask me clarifying questions
before you start if anything is underspecified.

CONTEXT
- Personal Jellyfin server, ~500-movie curated/cinephile library (classics, auteurs, world
  cinema), on a home NAS over LAN.
- The owner already built a deep metadata layer in Jellyfin using Collections (BoxSets):
  - 7 top-level "group" collections, each a collection-of-collections: New Releases,
    Directors, Decades, Genres, Studios, Curated, Seasonal.
  - ~130 child collections: Directors → 37 auteurs (Nolan, Scorsese, Coen Brothers…, 3+ films
    each); Decades → 1950s & Earlier … 2020s; Genres → fine combos (Action Thriller, Romantic
    Comedy…) + broad genres; Studios → A24, Warner, Pixar… (28); Curated → Film School
    Classics, Asian Cinema, Oscar Buzz, Critically Acclaimed; Seasonal → Christmas, Halloween,
    4th of July.
  - Rich art already exists for every tile: generated typographic graphics (group + decade
    tiles), director headshot posters + indigo name-card backdrops, real studio-logo backdrops,
    and unique de-duped movie posters + 16:9 backdrops for everything else.

THE GOAL
Replace clunky off-the-shelf Apple TV clients with a home screen that feels like Netflix / Max
/ Apple TV+: a hero/spotlight at the top, then endless vertical scroll of horizontal carousels
("shelves"), each a different lens into the library — a genre, a year, a director, a studio, a
curated set, and randomized "explore" feeds — all leaning on the big backdrop art. It should
feel alive and explorable, never the same twice.

TARGETS / CONSTRAINTS
- Phase 1 is a WEB proof-of-concept (laptop browser) hitting the Jellyfin REST API against the
  real library — so the design MUST be implementable in React/HTML/CSS.
- Phase 2 ports the validated design to a native tvOS app (SwiftUI / a Swiftfin fork) driven by
  the Apple TV focus engine: D-pad navigation, focus scaling, no pointer. Design for the 10-foot
  UI + focus model from the start (large targets, bold focus state, horizontal-carousel nav).
- Data: Jellyfin REST API — Items, Collections/BoxSets, Images (Primary + Backdrop), Genres,
  Studios, People (directors), ProductionYear, CommunityRating, IsFavorite, playback position.

DELIVERABLES (produce all)
1. Product spec (PRD): vision/north-star; home-screen information architecture; the full shelf
   taxonomy with the logic for each (fixed vs. dynamic/rotating/randomized, item count, sort);
   navigation model (home → shelf → collection grid → item detail → play); detail-page design;
   and a component inventory (hero/spotlight; carousel; card variants: backdrop card, poster
   card, typographic/graphic tile, director-portrait card, studio-logo card).
2. Visual design system: dark theme, typography, spacing/grid, card aspect ratios & sizing,
   focus/hover states, motion/transitions — specified to work on BOTH web and tvOS.
3. Interactive HTML mockups (artifacts): the home screen (hero + several differentiated shelves
   with placeholder backdrop art), a shelf/collection grid, and an item detail page. Make it
   feel premium and streamer-grade.
4. A "dynamic shelf engine" design: concrete rules for an ever-fresh explorable home — rotating
   spotlight, "Spotlight on [random director]", "[random year] in film", "If you like [genre]",
   "From the [studio] vault", "Acclaimed & unwatched", seeded/randomized per session — described
   precisely enough to implement against the Jellyfin API.
5. Open design questions + phasing (web PoC scope vs. deferred to native).

Output the written spec as structured markdown, plus the mockups as separate artifacts.
