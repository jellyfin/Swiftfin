//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoCoreGenre

//
// A curated "core" genre bucket shown as the first line of the Genres page. Each maps to several
// fine-grain server genres by keyword, so it works without hardcoding the server's exact genre
// names. Selecting one opens a page of only that bucket's fine-grain genre shelves.
struct BrunoCoreGenre: Identifiable, Hashable {

    let id: String
    let title: String
    let keywords: [String]

    /// Does a fine-grain server genre (e.g. "Science Fiction", "Adventure") belong to this bucket?
    func matches(_ genreName: String) -> Bool {
        let lowered = genreName.lowercased()
        return keywords.contains { lowered.contains($0) }
    }

    static let all: [BrunoCoreGenre] = [
        .init(id: "action", title: "Action", keywords: ["action", "adventure", "martial", "war", "western", "spy"]),
        .init(
            id: "scifi-fantasy",
            title: "Sci-Fi & Fantasy",
            keywords: ["sci-fi", "scifi", "science fiction", "fantasy", "superhero", "supernatural"]
        ),
        // "romcom"/"rom-com" so the curated "RomCom All-Timers" shelf lands in this bucket
        // (its name contains neither "romance" nor "romantic").
        .init(id: "romance", title: "Romance", keywords: ["romance", "romantic", "romcom", "rom-com"]),
        .init(id: "comedy", title: "Comedy", keywords: ["comedy", "comedies", "sitcom", "stand-up"]),
        .init(id: "drama", title: "Drama", keywords: ["drama"]),
    ]
}

// MARK: - BrunoGenresView (tvOS only)

//
// The Genres page (roadmap §4 + core panel). With `core == nil`: a core-category panel as the
// first line (Action · Sci-Fi & Fantasy · Romance · Comedy · Drama), then the mixed-together
// sub-genre shelves. With a `core` set: only the fine-grain genre shelves in that bucket.
struct BrunoGenresView: View {

    let parent: BaseItemDto
    let core: BrunoCoreGenre?

    @StateObject
    private var viewModel = BrunoBoxSetShelvesViewModel()

    /// The COMMITTED core-genre filter — the one `shownCategories` actually filters on. Changed IN
    /// PLACE (no navigation push, no refetch) so switching genres is instant — the full set is already
    /// loaded in `viewModel`. Driven by the debounced commit ~150 ms after focus settles, so a fast
    /// left-right scrub across the pill row rebuilds the shelf stack exactly ONCE, not per pill.
    @State
    private var selectedCore: BrunoCoreGenre?

    /// The FOCUSED core (transient, set instantly as the focus ring passes each pill). Drives the pill
    /// highlight (cheap) so highlighting feels instant while the shelves settle via `selectedCore`.
    /// `nil` ⇒ the "All" chip. A non-toggling target: the focused pill, never cleared by re-focusing.
    @State
    private var focusedCore: BrunoCoreGenre?

    /// The pending debounced write of `focusedCore → selectedCore`. Stored so each new focus cancels
    /// the previous pending commit (coalescing a scrub into one rebuild) and `onDisappear` can cancel it.
    @State
    private var commitTask: Task<Void, Never>?

    /// INV-7 guard: true only AFTER the first paint, so the focus engine's initial focus assignment
    /// to the pill row can't fire a filter on cold enter. Until this flips, a focus-driven commit no-ops.
    @State
    private var filterRowAppeared = false

    /// The hero's featured item, computed ONCE from the FULL unfiltered set and held fixed. A pill
    /// change must never reload the 720pt hero backdrop, so this is decoupled from `shownCategories`.
    @State
    private var featuredItem: BaseItemDto?

    init(parent: BaseItemDto, core: BrunoCoreGenre?) {
        self.parent = parent
        self.core = core
        _selectedCore = State(initialValue: core)
        _focusedCore = State(initialValue: core)
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
                // No sub-genre card row: the core panel is the only chrome up top; each shelf's
                // "Show all" reaches the full grid. Selecting a core re-filters `shownCategories`
                // from the already-loaded set — instant, no spinner.
                BrunoCategoryShelves(
                    categories: shownCategories,
                    eyebrow: "If You Like",
                    header: AnyView(corePanel),
                    showCategoryRow: false,
                    // INV-7 / decoupled hero: the FIXED item from the full set, never re-derived per
                    // pill, so a filter change can't reload the hero backdrop (heroEyebrow may still vary).
                    featured: featuredItem,
                    heroEyebrow: selectedCore.map { "\($0.title) Pick" } ?? "Featured Film"
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
        .onDisappear {
            commitTask?.cancel()
            commitTask = nil
        }
    }

    /// All fine-grain genres when nothing is selected; only the bucket's genres when a core is active.
    private var shownCategories: [BrunoCollectionCategory] {
        guard let selectedCore else { return viewModel.categories }
        return viewModel.categories.filter { selectedCore.matches($0.name) }
    }

    private var corePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse by".uppercased())
                .font(.brunoBody(20, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.bruno.accent)
                .padding(.horizontal, 50)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    // "All" chip: a first-class in-HStack pill (matches Kids' uniformity) and the only
                    // path back to the unfiltered set. Highlighted off the FOCUSED value (instant).
                    BrunoSelectorCard(
                        title: "All",
                        isSelected: focusedCore == nil,
                        selectsOnFocus: true
                    ) {
                        commitFocus(nil)
                    }

                    ForEach(BrunoCoreGenre.all) { coreGenre in
                        BrunoSelectorCard(
                            // Highlight off FOCUSED (cheap/instant); the filter follows ~150 ms later.
                            title: coreGenre.title,
                            isSelected: focusedCore?.id == coreGenre.id,
                            // Move-to-select: landing the ring on a pill focuses it; the shelves settle
                            // once via the debounced commit (non-toggling — "All" is the only clear path).
                            selectsOnFocus: true
                        ) {
                            commitFocus(coreGenre)
                        }
                    }
                }
                .padding(.horizontal, 50)
                .padding(.vertical, 8)
            }
            .focusSection()
        }
        // INV-7: flip the appeared guard only after the first paint, so the focus engine's initial
        // assignment to the pill row can't fire a commit on cold enter (hero shows the unfiltered set).
        .task { filterRowAppeared = true }
    }

    /// Record the focused core instantly (drives the highlight) and DEBOUNCE the write to the
    /// committed `selectedCore` (~150 ms after focus settles), so a fast scrub across the row rebuilds
    /// the shelf stack at most once. No-ops before first paint (INV-7) and when nothing changed.
    private func commitFocus(_ core: BrunoCoreGenre?) {
        guard filterRowAppeared else { return }
        guard focusedCore?.id != core?.id || selectedCore?.id != core?.id else { return }

        focusedCore = core
        commitTask?.cancel()
        commitTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            // Commit only if focus still rests on the same pill (no-op if already committed there).
            guard focusedCore?.id == core?.id, selectedCore?.id != core?.id else { return }
            selectedCore = core
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No genres yet")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("Genres from this server will appear here.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - NavigationRoute

extension NavigationRoute {

    @MainActor
    static func brunoGenres(parent: BaseItemDto, core: BrunoCoreGenre?) -> NavigationRoute {
        NavigationRoute(
            id: "bruno-genres-\(parent.id ?? parent.displayTitle)-\(core?.id ?? "all")"
        ) {
            BrunoGenresView(parent: parent, core: core)
        }
    }
}
