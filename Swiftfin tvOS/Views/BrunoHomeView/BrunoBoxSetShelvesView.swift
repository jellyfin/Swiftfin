//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoBoxSetShelvesView (tvOS only)

//
// Drill-in for a single group BoxSet (Genres or Decades): a shelf per child sub-group (each
// genre / each decade), capped, with "Show all" -> the full grid for that sub-group (roadmap §4).
// Mirrors the Collections hub exactly via the shared BrunoCategoryShelves.
struct BrunoBoxSetShelvesView: View {

    let parent: BaseItemDto

    @StateObject
    private var viewModel = BrunoBoxSetShelvesViewModel()

    /// Decades only: the COMMITTED decade filter — what `shownCategories` filters on AND what drives
    /// the per-year fetch (the `onChange` below). In-place, no refetch of the base set. Driven by the
    /// debounced commit ~150 ms after focus settles, so a fast scrub rebuilds the shelves (and fires
    /// the per-year fetch) exactly ONCE, not per pill.
    @State
    private var selectedDecade: String?

    /// The FOCUSED decade (transient, set instantly as the focus ring passes each pill). Drives the
    /// pill highlight (cheap) for instant feedback while the shelves settle via `selectedDecade`.
    /// `nil` ⇒ the "All" chip.
    @State
    private var focusedDecade: String?

    /// The pending debounced write of `focusedDecade → selectedDecade`. Stored so each new focus
    /// cancels the previous pending commit (coalescing a scrub) and `onDisappear` can cancel it.
    @State
    private var commitTask: Task<Void, Never>?

    /// INV-7 guard: true only AFTER the first paint, so the focus engine's initial focus assignment to
    /// the pill row can't fire a filter (or the per-year fetch) on cold enter. Until set, a commit no-ops.
    @State
    private var filterRowAppeared = false

    /// The hero's featured item, computed ONCE from the FULL unfiltered set and held fixed. A pill
    /// change must never reload the 720pt hero backdrop, so this is decoupled from `shownCategories`.
    @State
    private var featuredItem: BaseItemDto?

    private var isDecades: Bool {
        parent.displayTitle.lowercased() == "decades"
    }

    /// The decade category currently selected by a pill (nil ⇒ "All", the overview).
    private var selectedDecadeCategory: BrunoCollectionCategory? {
        guard let selectedDecade else { return nil }
        return viewModel.categories.first { $0.name == selectedDecade }
    }

    /// Decades use a pill selector. "All" (nil) keeps the decade-overview (one shelf per decade).
    /// Selecting a specific decade swaps the SHELVES below to one shelf PER YEAR of that decade
    /// (memoized in the view model); the catch-all "1950s & Earlier" has no fixed 10-year window, so
    /// it stays its single overview shelf. The PILLS keep iterating viewModel.categories regardless,
    /// so they never vanish. Falls back to the single decade shelf until the per-year fetch lands.
    private var shownCategories: [BrunoCollectionCategory] {
        guard isDecades, let selectedDecade, let category = selectedDecadeCategory else {
            return viewModel.categories
        }
        if let id = category.boxSet.id, let perYear = viewModel.yearShelvesByDecadeID[id] {
            return perYear
        }
        // Not yet fetched (or non-splittable "1950s & Earlier"): show the single decade shelf.
        return viewModel.categories.filter { $0.name == selectedDecade }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.categories.isEmpty {
                emptyState
            } else {
                // Decades mirror the Genres page: a pill row instead of the big decade cards,
                // switching the shown decade in place. Other groups (Curated) keep the card row.
                BrunoCategoryShelves(
                    categories: shownCategories,
                    eyebrow: lensEyebrow,
                    header: isDecades ? AnyView(decadePanel) : nil,
                    showCategoryRow: !isDecades,
                    // INV-7 / decoupled hero: the FIXED item from the full set, never re-derived per
                    // pill, so a decade change can't reload the hero backdrop.
                    featured: featuredItem,
                    heroEyebrow: "Featured Film",
                    // Decade surface opts in to per-poster release dates; Genres/Curated keep the default.
                    showsDate: isDecades,
                    // Decades only: scroll the pills to the top on a COMMITTED decade change (the
                    // debounced value, so a fast scrub scrolls once on settle). Other groups pass nil.
                    pillScrollKey: isDecades ? selectedDecade : nil
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load(parent: parent) }
        }
        // Compute the hero ONCE from the FULL unfiltered set when categories land (and never per pill).
        .onChange(of: viewModel.categories.map(\.id)) { _, _ in
            featuredItem = brunoFeaturedItem(in: viewModel.categories)
        }
        // Trigger the COMPLETE per-year fetch when a specific decade is COMMITTED (the committed
        // selectedDecade, not the transient focus). Fires at most once per settled focus because the
        // debounce coalesces a scrub into one write. Memoized in the view model, so re-selecting is a
        // no-op. The resulting shelf-set swap is non-animated (no withAnimation anywhere on this
        // transition) and honors reduce-motion by construction — INV-9.
        .onChange(of: selectedDecade) { _, _ in
            guard let category = selectedDecadeCategory else { return }
            Task { await viewModel.loadYearShelves(for: category) }
        }
        .onDisappear {
            commitTask?.cancel()
            commitTask = nil
        }
    }

    private var decadePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by Decade".uppercased())
                .font(.brunoBody(20, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.bruno.accent)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    // "All" chip: a first-class in-HStack pill (matches Kids' uniformity) and the only
                    // path back to the decade-overview. Highlighted off the FOCUSED value (instant).
                    BrunoSelectorCard(
                        title: "All",
                        isSelected: focusedDecade == nil,
                        selectsOnFocus: true
                    ) {
                        commitFocus(nil)
                    }

                    // Keep iterating viewModel.categories (NOT shownCategories) so pills never vanish
                    // when a specific decade swaps the shelves to per-year.
                    ForEach(viewModel.categories) { category in
                        BrunoSelectorCard(
                            // Highlight off FOCUSED (cheap/instant); the filter + per-year fetch follow
                            // ~150 ms later via the committed value.
                            title: category.name,
                            isSelected: focusedDecade == category.name,
                            // Move-to-select: landing the ring focuses the pill; the shelves settle once
                            // via the debounced commit (non-toggling — "All" is the only clear path).
                            selectsOnFocus: true
                        ) {
                            commitFocus(category.name)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
            }
            .focusSection()
        }
        // INV-7: flip the appeared guard only after the first paint, so the focus engine's initial
        // assignment to the pill row can't fire a commit (or per-year fetch) on cold enter.
        .task { filterRowAppeared = true }
    }

    /// Record the focused decade instantly (drives the highlight) and DEBOUNCE the write to the
    /// committed `selectedDecade` (~150 ms after focus settles), so a fast scrub rebuilds the shelves —
    /// and fires the per-year fetch — at most once. No-ops before first paint (INV-7) and when unchanged.
    private func commitFocus(_ decade: String?) {
        guard filterRowAppeared else { return }
        guard focusedDecade != decade || selectedDecade != decade else { return }

        focusedDecade = decade
        commitTask?.cancel()
        commitTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            // Commit only if focus still rests on the same pill (no-op if already committed there).
            guard focusedDecade == decade, selectedDecade != decade else { return }
            selectedDecade = decade
        }
    }

    /// Singularised group name ("Genres" -> "Genre", "Decades" -> "Decade").
    private var eyebrow: String {
        let name = parent.displayTitle
        return name.count > 1 && name.hasSuffix("s") ? String(name.dropLast()) : name
    }

    /// Lens-style shelf eyebrow per surface (mockup lens system); falls back to the singular name.
    private var lensEyebrow: String {
        switch parent.displayTitle.lowercased() {
        case "decades": "Browse by Decade"
        case "curated": "Curated"
        default: eyebrow
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("Nothing here yet")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("This collection has no sub-categories to show.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BrunoBoxSetShelvesViewModel

@MainActor
final class BrunoBoxSetShelvesViewModel: ViewModel {

    @Published
    private(set) var categories: [BrunoCollectionCategory] = []
    @Published
    private(set) var isLoading = true

    /// Per-decade-id → that decade's complete film set regrouped into one synthetic category PER
    /// YEAR (newest-year-first, then an "Other" catch-all). Memoized: selecting a decade fetches its
    /// COMPLETE set once (the inline shelf children are a 13-item shuffled preview — far too sparse
    /// to bucket into 10 years), then re-selecting reads straight from here. Keyed by the decade
    /// sub-BoxSet id, which is per-snapshot, so a user/library switch can't serve stale buckets.
    @Published
    private(set) var yearShelvesByDecadeID: [String: [BrunoCollectionCategory]] = [:]

    /// One past the shelf cap so the shared scaffold can tell whether "Show all" is warranted.
    private let perShelfFetch = 13

    /// Re-entrancy guard: the in-flight (or completed) load for THIS view model instance. The
    /// cache read below is `await`ed, so a fast double-`onFirstAppear` (two pushes before the first
    /// suspension resumes) could otherwise launch two concurrent fan-outs. We start the load once,
    /// stash the Task, and have later calls await the same Task instead of re-running. A new
    /// @StateObject per push means this only coalesces re-entry within one push's lifetime — exactly
    /// the double-fire window; cross-push reuse comes from BrunoBoxSetShelvesCache.
    private var loadTask: Task<Void, Never>?

    /// Day-stable seed for shelf shuffling — same order all day, reshuffles the next day.
    private static var shuffleSeed: UInt32 {
        UInt32(truncatingIfNeeded: Int(Date().timeIntervalSince1970 / 86400))
    }

    func load(parent: BaseItemDto) async {
        // Re-entrancy guard: if a load is already running/done on this instance, await it instead of
        // launching a second fan-out. The `await` on the cache read is the suspension a quick
        // re-push could slip through, so the guard wraps the whole thing.
        if let loadTask {
            await loadTask.value
            return
        }
        let task = Task { await performLoad(parent: parent) }
        loadTask = task
        await task.value
    }

    private func performLoad(parent: BaseItemDto) async {
        guard let userSession, let parentID = parent.id else {
            isLoading = false
            return
        }

        let client = userSession.client
        let userID = userSession.user.id

        // Cross-push cache: re-entering this drill-in (Genres / Decades / Curated) within the TTL
        // reuses the categories the fan-out already produced — skipping the 20+ request storm — since
        // the @StateObject is re-instantiated per navigation push and would otherwise re-run it every
        // time. Keyed by (userID, parentID); 300s TTL bounds staleness of the children's
        // enableUserData (watched / resume ticks), matching the snapshot cache's contract (INV-5).
        if let cached = await BrunoBoxSetShelvesCache.shared.value(userID: userID, parentID: parentID) {
            categories = cached
            isLoading = false
            return
        }

        // Genre rows are biased to modern films (owner request): pre-1985 titles are dropped from the
        // "If You Like {genre}" shelves and the same film can't fill two overlapping genre rows. They
        // still appear in each genre's full "Show all" grid (sunk to the bottom). Decades / Curated /
        // any other group are NOT biased — they exist precisely to surface older eras. We fetch a
        // deeper page when biased so enough modern titles survive the filter to fill a preview row.
        let recencyBiased = parent.displayTitle.lowercased() == "genres"
        let childFetch = recencyBiased ? 60 : perShelfFetch

        let subGroups = await Self.fetchChildren(
            client: client,
            userID: userID,
            parentID: parentID,
            limit: 100
        )

        // Fetch each sub-group's children concurrently; preserve server order via the index.
        var indexed: [(Int, BrunoCollectionCategory)] = []
        await withTaskGroup(of: (Int, BaseItemDto, [BaseItemDto]).self) { group in
            for (index, subGroup) in subGroups.enumerated() {
                guard let subID = subGroup.id else { continue }
                let fetch = childFetch
                group.addTask {
                    let children = await Self.fetchChildren(
                        client: client,
                        userID: userID,
                        parentID: subID,
                        limit: fetch
                    )
                    return (index, subGroup, children)
                }
            }

            for await (index, subGroup, children) in group {
                let modern = recencyBiased ? BrunoRecencyBias.modernOnly(children) : children
                // Seeded shuffle so shelves read varied rather than alphabetical (owner request).
                // Day-stable seed + per-shelf offset → stable within a day, fresh the next.
                let shown = BrunoRNG.shuffled(modern, seed: Self.shuffleSeed &+ UInt32(truncatingIfNeeded: index))
                guard shown.isNotEmpty else { continue }
                indexed.append((
                    index,
                    BrunoCollectionCategory(boxSet: subGroup, children: shown, recencyBiased: recencyBiased)
                ))
            }
        }

        let baseOrdered = indexed
            .sorted { $0.0 < $1.0 }
            .map(\.1)

        // Decades render newest-first (owner request): sort by leading year descending, which also
        // drops the "1950s & Earlier" catch-all (year 1950, the smallest) to the bottom. Other
        // groups keep server order.
        let isDecades = parent.displayTitle.lowercased() == "decades"
        let ordered = isDecades
            ? baseOrdered.sorted { Self.leadingYear($0.name) > Self.leadingYear($1.name) }
            : baseOrdered

        let result = recencyBiased ? Self.dedupeAcrossCategories(ordered) : ordered
        categories = result
        isLoading = false

        // Store the fan-out result so a re-entry within the TTL skips the request storm. Empty results
        // are not cached (let a later push retry), mirroring the snapshot cache.
        if result.isNotEmpty {
            await BrunoBoxSetShelvesCache.shared.store(result, userID: userID, parentID: parentID)
        }
    }

    // MARK: - Per-year decade shelves (Step 3b)

    /// Decade names that must NOT be split into per-year shelves: the open-ended catch-all has no
    /// fixed 10-year window, so it stays a single shelf (owner request).
    private static func isSplittableDecade(_ name: String) -> Bool {
        // "1950s & Earlier" is the sole non-window bucket; every "NNNNs" decade splits.
        !name.localizedCaseInsensitiveContains("earlier")
    }

    /// Fetch a decade's COMPLETE film set and regroup it into one synthetic category per year
    /// (newest-year-first) plus an "Other" catch-all. Memoized per decade BoxSet id — a no-op once
    /// loaded, and skipped entirely for the non-splittable "1950s & Earlier". Pure regroup given the
    /// fetched set (INV-3): the only ordering inputs are premiereDate / productionYear / id.
    func loadYearShelves(for decade: BrunoCollectionCategory) async {
        guard let decadeID = decade.boxSet.id,
              Self.isSplittableDecade(decade.name),
              yearShelvesByDecadeID[decadeID] == nil,
              let userSession
        else { return }

        let client = userSession.client
        let userID = userSession.user.id
        let decadeBoxSet = decade.boxSet

        let complete: [BaseItemDto]
        do {
            complete = try await BrunoItemPaging.fetchAll(client: client) { startIndex, limit in
                var parameters = Paths.GetItemsParameters()
                parameters.userID = userID
                parameters.parentID = decadeID
                // Decades hold their films as direct children; honour the parent's own recursion
                // policy for safety if the curation ever nests them.
                parameters.isRecursive = decadeBoxSet.isRecursiveCollection
                // The decades curation is movies-only (verified live: every 2000s child is a Movie).
                parameters.includeItemTypes = [.movie]
                // premiereDate & productionYear return implicitly; .genres keeps brunoFeaturedItem /
                // brunoHeroEligible working on the surface's hero. NO shuffle — completeness matters.
                parameters.fields = .MinimumFields + [.genres]
                parameters.enableUserData = true
                parameters.startIndex = startIndex
                parameters.limit = limit
                return parameters
            }
        } catch {
            complete = []
        }

        yearShelvesByDecadeID[decadeID] = Self.yearCategories(
            from: complete,
            decade: decadeBoxSet
        )
    }

    /// Regroup a decade's complete film list into per-year synthetic categories (newest-year-first)
    /// plus a trailing "Other" catch-all. Deterministic and side-effect free. `decade` is the REAL
    /// decade BoxSet — threaded onto each synthetic category as `gridParent` so "Show all" scopes the
    /// live year-filtered library correctly.
    private static func yearCategories(
        from items: [BaseItemDto],
        decade: BaseItemDto
    ) -> [BrunoCollectionCategory] {
        let decadeName = decade.displayTitle
        let decadeStart = leadingYear(decadeName) // e.g. "2000s" → 2000
        let window = decadeStart ... (decadeStart + 9) // [2000, 2009] inclusive

        // Bucket by resolved year; the Other key (nil) holds anything with no year OR out-of-window.
        var buckets: [Int?: [BaseItemDto]] = [:]
        for item in items {
            let resolved = resolvedYear(of: item)
            let key: Int? = (resolved.map { window.contains($0) } == true) ? resolved : nil
            buckets[key, default: []].append(item)
        }

        // Intra-year order: premiereDate descending, then id as a stable tiebreaker (NO BrunoRNG).
        func ordered(_ films: [BaseItemDto]) -> [BaseItemDto] {
            films.sorted { lhs, rhs in
                let lDate = lhs.premiereDate ?? .distantPast
                let rDate = rhs.premiereDate ?? .distantPast
                if lDate != rDate { return lDate > rDate }
                return (lhs.id ?? "") < (rhs.id ?? "")
            }
        }

        let slug = decadeName.lowercased()
        var out: [BrunoCollectionCategory] = []

        // Real years, newest-first; skip empty years.
        for year in window.reversed() {
            guard let films = buckets[year], films.isNotEmpty else { continue }
            out.append(yearCategory(
                id: "decade-\(slug)-year-\(year)",
                title: "\(year)",
                films: ordered(films),
                decade: decade,
                year: year
            ))
        }

        // Other catch-all (nil / out-of-window) sorts LAST; skipped when empty so nothing is dropped
        // yet no empty shelf appears. No single year applies → Show-all opens the decade's full
        // library (gridYear nil).
        if let other = buckets[nil], other.isNotEmpty {
            out.append(yearCategory(
                id: "decade-\(slug)-other",
                title: "Other",
                films: ordered(other),
                decade: decade,
                year: nil
            ))
        }

        return out
    }

    /// A synthetic per-year category. The boxSet is a placeholder whose displayTitle is the label and
    /// whose id is a STABLE UNIQUE string (INV-2) so it never collides across years or with the
    /// parent decade category. drillStyle .grid + gridParent/gridYear so "Show all" reaches the full
    /// year-filtered live library (not the landscape franchise grid that .items routes to).
    private static func yearCategory(
        id: String,
        title: String,
        films: [BaseItemDto],
        decade: BaseItemDto,
        year: Int?
    ) -> BrunoCollectionCategory {
        BrunoCollectionCategory(
            boxSet: BaseItemDto(id: id, name: title),
            children: films,
            drillStyle: .grid,
            gridParent: decade,
            gridYear: year
        )
    }

    /// Resolve an item's release year: the calendar year of premiereDate (UTC, so a UTC-midnight
    /// date can't roll into an adjacent year on a non-UTC device), else productionYear, else nil.
    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()

    private static func resolvedYear(of item: BaseItemDto) -> Int? {
        if let premiere = item.premiereDate {
            return utcCalendar.component(.year, from: premiere)
        }
        return item.productionYear
    }

    /// The leading numeric year in a decade sub-group name ("2020s" → 2020, "1950s & Earlier" →
    /// 1950); 0 when none, so any non-decade name sorts last under the descending sort.
    private static func leadingYear(_ name: String) -> Int {
        Int(name.prefix { $0.isNumber }) ?? 0
    }

    /// Drop a film from every genre shelf after the first that lists it (server order wins), so the
    /// same title can't fill both "Romantic Comedy" and "Romantic Drama" when the server's genre tags
    /// overlap. A category emptied by the pass is dropped. Duplicates still resurface in each genre's
    /// full "Show all" grid — they're only deduped across the preview rows.
    private static func dedupeAcrossCategories(_ categories: [BrunoCollectionCategory]) -> [BrunoCollectionCategory] {
        var seen: Set<String> = []
        var out: [BrunoCollectionCategory] = []
        for category in categories {
            let fresh = category.children.filter { item in
                guard let id = item.id else { return true }
                return seen.insert(id).inserted
            }
            guard fresh.isNotEmpty else { continue }
            out.append(BrunoCollectionCategory(
                boxSet: category.boxSet,
                children: fresh,
                drillStyle: category.drillStyle,
                lens: category.lens,
                recencyBiased: category.recencyBiased
            ))
        }
        return out
    }

    private nonisolated static func fetchChildren(
        client: JellyfinClient,
        userID: String,
        parentID: String,
        limit: Int
    ) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userID
        parameters.parentID = parentID
        // .genres feeds the hero child-safety filter (brunoHeroEligible) on this drill-in's
        // "Featured Film"; MinimumFields omits genres, which would make the filter a no-op.
        parameters.fields = .MinimumFields + [.genres]
        parameters.enableUserData = true
        parameters.limit = limit
        do {
            let response = try await client.send(Paths.getItems(parameters: parameters))
            return response.value.items ?? []
        } catch {
            return []
        }
    }
}

// MARK: - BrunoBoxSetShelvesCache

//
// In-memory cache so re-entering a browse drill-in (Genres / Decades / Curated) reuses the
// categories its fan-out already produced instead of re-running the 20+ request storm on every
// navigation push (the view's @StateObject is re-instantiated per push). Mirrors
// BrunoLibrarySnapshot.Cache: an actor, keyed by (userID, parentID), short TTL.
//
// TTL (not session-permanent) because the cached children carry enableUserData=true (watched /
// resume state); a permanent cache would show stale watched ticks (INV-5). 300s bounds staleness
// and matches the snapshot cache's contract. Keyed by userID so a user switch never serves stale
// data, and by parentID so each group (Genres / Decades / Curated …) caches independently. Per-year
// decade splits are NOT cached here — they're memoized separately in `yearShelvesByDecadeID`.
private actor BrunoBoxSetShelvesCache {

    static let shared = BrunoBoxSetShelvesCache()

    private struct Entry {
        let userID: String
        let categories: [BrunoCollectionCategory]
        let loadedAt: Date
    }

    /// Keyed by parentID; the entry also pins the userID so a user switch is treated as a miss.
    private var entries: [String: Entry] = [:]

    private let maxAge: TimeInterval = 300

    func value(userID: String, parentID: String) -> [BrunoCollectionCategory]? {
        guard let entry = entries[parentID],
              entry.userID == userID,
              Date().timeIntervalSince(entry.loadedAt) < maxAge
        else {
            // Evict on expiry / user mismatch so a stale entry can't linger past its TTL.
            entries[parentID] = nil
            return nil
        }
        return entry.categories
    }

    func store(_ categories: [BrunoCollectionCategory], userID: String, parentID: String) {
        guard categories.isNotEmpty else { return }
        entries[parentID] = Entry(userID: userID, categories: categories, loadedAt: Date())
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoCategoryShelves(parent: BaseItemDto) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-shelves-\(parent.id ?? parent.displayTitle)",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            BrunoBoxSetShelvesView(parent: parent)
        }
    }
}
