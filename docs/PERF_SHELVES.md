# Bruno tvOS — Shelf scroll performance (handoff for a separate thread)

> **Symptom (owner, on real Apple TV):** "Heavy frame slow-down on every *vertical* shelf
> movement." Felt on the browse surfaces that stack many horizontal shelves: the **Collections**
> tab, **Genres** core/sub pages, **Decades**, and the new **Curated** shelves — anything rendered
> by `BrunoCategoryShelves`. Horizontal scrolling *within* a shelf is fine; the jank is moving the
> focus/scroll **between rows**.

This is a known-shape tvOS problem, not yet fixed. Below is the suspected cause and a ranked set of
fixes so a separate thread can pick it up without re-deriving the context. **Profile first — don't
blind-rewrite.**

## Suspected root cause

`BrunoCategoryShelves` (and `BrunoHomeView`) build the page as:

```
ScrollView {
    LazyVStack(spacing: 36) {
        header / category card row
        ForEach(categories) { shelf ->
            VStack { titles; BrunoShelfRow }   // BrunoShelfRow = CollectionHStack (UICollectionView)
        }
    }
}
```

So the page is **N independent `UICollectionView`s** (one per shelf, via `CollectionHStack`) hosted
inside a SwiftUI `ScrollView`+`LazyVStack`. On tvOS this is a classic jank source:

- Each `CollectionHStack` is a `UIViewRepresentable` wrapping a collection view. Many of them nested
  in a SwiftUI scroll container fight over focus, intrinsic-size measurement, and layout passes.
- Vertical focus moves trigger re-measure / re-layout of rows as they enter the viewport.
- `LazyVStack` virtualizes by SwiftUI's heuristics, which interact poorly with the embedded
  collection views (they may all stay alive / keep cells realized).

Stock Swiftfin's home (`HomeView`) does **not** do this — it hosts everything in a single
collection (`CollectionVStack` / `PosterHStack` inside one scroll context) rather than N nested
collection views. That's the likely target architecture.

## Ranked fixes (cheapest → biggest)

1. **Confirm the cause with Instruments (Animation Hitches / Time Profiler) on-device.** Watch for
   layout passes and `UICollectionView` work spiking on each vertical focus change. ~30 min, gates
   everything below.

2. **Trim what each shelf realizes.** `BrunoShelfRow` uses `.dataPrefix(40)` and the callers cap at
   `shelfCap = 36`. A shelf is a *preview* — "Show all" exists for the rest. Drop the inline cap to
   ~12–15 and `dataPrefix` to match. Fewer realized cells per row → less per-row work. Low risk,
   likely a real win. Files: `BrunoShelfRow.swift`, `BrunoCategoryShelves.swift:76`,
   `BrunoBoxSetShelvesView.swift:78` (`perShelfFetch`).

3. **Drop per-card cost during scroll.** `PosterButton` applies `.posterShadow()` + `hoverEffect`.
   Offscreen shadow rendering is expensive on tvOS at volume. Test removing/cheapening the shadow on
   these shelves and measure. File: `Swiftfin tvOS/Components/PosterButton.swift`.

4. **Render fewer shelves up front.** Cap the number of shelves materialized before scroll and grow
   on demand (the home tab already has an explore-tail/sentinel pattern in `BrunoHomeViewModel`
   `appendExplore`; `BrunoCategoryShelves` does not — it `ForEach`es all categories at once).

5. **Architectural fix (biggest, do last):** replace `ScrollView { LazyVStack { CollectionHStack… } }`
   with the stock single-collection pattern (`CollectionVStack` hosting `PosterHStack` rows) so the
   whole page is one collection view instead of N nested ones. This is what stock `HomeView` does.
   Highest effort, highest payoff, most regression risk (focus engine, "Show all" trailing card,
   the big gradient category row). Verify focus + Show-all alignment on-device after.

## Files

- `Swiftfin tvOS/Views/BrunoHomeView/BrunoCategoryShelves.swift` — the shared shelves scaffold
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoShelfRow.swift` — one shelf (`CollectionHStack`, dataPrefix)
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoBoxSetShelvesView.swift` — Decades/Curated/Genres drill
- `Swiftfin tvOS/Views/BrunoHomeView/BrunoHomeView.swift` — home (same nested pattern)
- `Swiftfin tvOS/Components/PosterButton.swift`, `PosterHStack.swift` — card + stock row for comparison
- Stock reference for the target architecture: `Swiftfin tvOS/Views/HomeView/…`

## Notes / constraints

- Build in the **main checkout** (`/Users/danielbrunelle/Documents/Claude/Projects/bruno`) — the
  worktree lacks `Carthage/Build/TVVLCKit.xcframework`, so a worktree build fails on the VLC
  framework, *not* on the code. See the build recipe in the tvOS handoff.
- Verify on the real Apple TV; the simulator does not reproduce tvOS focus/scroll cost faithfully.
