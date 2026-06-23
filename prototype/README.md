# Bruno

A streamer-style front-end for a self-hosted Jellyfin movie library — hero spotlight up top,
then endless horizontal "shelves" (genre, year, director, studio, curated, random explore),
all leaning on the big 16:9 backdrop art.

**Status / direction:** the team decided to **build the real native app directly** — a **Swiftfin
fork** for Apple TV — rather than ship the web PoC. The web app in this repo is kept as a design
sandbox/reference only. The active build contract is **[`NATIVE_FORK_PLAN.md`](NATIVE_FORK_PLAN.md)**:
an extreme-detail, one-shot execution plan (Swiftfin's architecture mapped) for a fresh autonomous
thread to fork Swiftfin and graft the Bruno home onto it. Design source of truth:
[`design_handoff_bruno/`](design_handoff_bruno/). (`bruno` is the app + repo name.)

## Quickstart

```bash
cd bruno
npm install
cp .env.example .env      # then fill in your Jellyfin URL / token / user id
npm run dev               # open the printed http://localhost:5173
```

A local `.env` with working values is already present (gitignored), so `npm run dev`
should connect immediately on your network.

## How it works

- **Vite + React.** The browser can't call the Jellyfin API directly (CORS), so in dev
  everything under `/jf` is proxied to the server (`vite.config.js`). The client uses
  same-origin relative URLs.
- **`src/api/jellyfin.js`** — thin REST client (group tiles / collections / recent / random,
  plus image URLs).
- **`src/App.jsx`** — the current PoC home: hero + three shelves (Browse the Collection =
  your 7 pinned group tiles, Recently Added, Surprise Me).

## Roadmap

1. **Design spec** (Claude Design thread) → see [`docs/DESIGN-PROMPT.md`](docs/DESIGN-PROMPT.md).
2. **This web PoC** → flesh out the dynamic "shelf engine", card variants, detail page, and
   navigation per the spec (see [`docs/PLAN.md`](docs/PLAN.md)).
3. **Validate in browser**, then **port to native tvOS** (SwiftUI / Swiftfin fork).

## Notes

- `.env` is gitignored — your API token never enters the repo. `.env.example` is the template.
- The server-side organization (collections, generated artwork, director portraits, studio
  logos, favorites) lives in Jellyfin and is built by `Build-Jellyfin-Collections.command`
  in the MovieCollection project. Bruno is purely a viewer over that.
