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

// MARK: - BrunoKidsView (tvOS only)

//
// The Kids tab: resolves the owner's kids library/libraries (which may be split into separate
// Movies and Shows libraries) and shows their merged contents, with All / Movies / TV Shows
// filter cards. The filter swaps the item types fed to BrunoCombinedLibrary, so it works whether
// kids content lives in one library or several.
struct BrunoKidsView: View {

    @StateObject
    private var viewModel = BrunoKidsViewModel()

    @State
    private var filter: KidsFilter = .all

    @State
    private var spotlightIndex = 0

    /// Measured scroll viewport height — used to reserve trailing room under the grid so a sparse
    /// filter (e.g. one row of TV Shows) can still scroll its last row into the focus band. See `content`.
    @State
    private var viewportHeight: CGFloat = 0

    @Router
    private var router

    /// INV-9: collapse the filter-select scroll-jump to an instant move when reduce-motion is on.
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Scroll anchor for the filter chip row — selecting a filter jumps the view here.
    private enum ScrollAnchor: Hashable {
        case filter
    }

    enum KidsFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case movies = "Movies"
        case shows = "TV Shows"
        case pixar = "Pixar"
        case disney = "Disney"

        var id: String {
            rawValue
        }

        // Studio filters are mutually exclusive by owner's rule: if Pixar is a studio on the title
        // it's a Pixar title, so it's excluded from Disney (no cross-population).
        func matches(_ item: BaseItemDto) -> Bool {
            switch self {
            case .all: true
            case .movies: item.type == .movie
            case .shows: item.type == .series
            case .pixar: item.hasStudio("pixar")
            case .disney: item.hasStudio("disney") && !item.hasStudio("pixar")
            }
        }
    }

    var body: some View {
        ZStack {
            // Ambient now tracks the kids spotlight (was a flat hero-less page).
            BrunoAmbientBackground(item: viewModel.heroItems.first)

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(2)
                    .tint(Color.bruno.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.parents.isEmpty {
                notFound
            } else {
                content
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .onFirstAppear {
            Task { await viewModel.load() }
        }
    }

    // Hero + filter chips + grid share ONE scroll plane (Movies/TV pattern), so the spotlight
    // scrolls away and vertical focus traverses hero <-> chips <-> grid with no special handling.
    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    if viewModel.heroItems.isNotEmpty {
                        BrunoHeroView(
                            items: viewModel.heroItems,
                            index: $spotlightIndex,
                            eyebrow: "Featured",
                            bleedsTop: true,
                            extraHeight: 160
                        )
                    }

                    filterBar
                        .id(ScrollAnchor.filter)

                    // Reserve at least a viewport of height for the grid region (top-aligned) so a
                    // sparse filter — e.g. "TV Shows" yielding one row — leaves empty space BELOW the
                    // row instead of pinning it to the content bottom. Without this, tvOS blocks
                    // Down-focus to that lone row (it can't be scrolled clear of the bottom edge) and
                    // the pills get shoved up. A no-op once the grid is taller than the viewport.
                    BrunoPosterGrid(items: filteredItems) { item in
                        router.route(to: .item(item: item))
                    }
                    .frame(
                        minHeight: viewportHeight > 0 ? viewportHeight : nil,
                        alignment: .top
                    )
                }
                .padding(.bottom, 60)
            }
            // Measure the scroll viewport (the ScrollView's own frame, independent of content height)
            // to size the grid's minHeight above.
            .background {
                GeometryReader { geo in
                    Color.clear
                        .onAppear { viewportHeight = geo.size.height }
                        .onChange(of: geo.size.height) { _, height in viewportHeight = height }
                }
            }
            // Jump the pills to the top when the (committed) filter changes — same framing as Decades.
            // INV-9: instant under reduce-motion. Re-scrolls land on the already-pinned anchor (no-op),
            // so a fast chip scrub doesn't thrash.
            .onChange(of: filter) { _, _ in
                let jump = { proxy.scrollTo(ScrollAnchor.filter, anchor: .top) }
                if reduceMotion {
                    jump()
                } else {
                    withAnimation(.easeInOut(duration: 0.35)) { jump() }
                }
            }
        }
    }

    private var filteredItems: [BaseItemDto] {
        viewModel.allItems.filter { filter.matches($0) }
    }

    private var filterBar: some View {
        HStack(spacing: 20) {
            ForEach(KidsFilter.allCases) { option in
                BrunoSelectorCard(
                    title: option.rawValue,
                    isSelected: option == filter,
                    style: .toggle,
                    // Move-to-select: landing the cursor on a chip applies it, no Select press.
                    selectsOnFocus: true
                ) {
                    filter = option
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 50)
        .focusSection()
    }

    private var notFound: some View {
        VStack(spacing: 16) {
            Text("Couldn't find “Kids”")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text("No Jellyfin kids library for this user.")
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BrunoKidsViewModel

@MainActor
final class BrunoKidsViewModel: ViewModel {

    @Published
    private(set) var parents: [BaseItemDto] = []
    @Published
    private(set) var allItems: [BaseItemDto] = []
    @Published
    private(set) var heroItems: [BaseItemDto] = []
    @Published
    private(set) var isLoading = true

    /// Candidate library names, plus a "kids" keyword fallback (matches "Kids Movies"/"Kids Shows"/…).
    private static let candidates = ["Kids", "Kids Movies", "Kids Shows", "Kids TV", "Kids Movies & Shows"]

    func load() async {
        guard let userSession else {
            isLoading = false
            return
        }

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let response = try? await userSession.client.send(Paths.getUserViews(parameters: parameters))

        parents = (response?.value.items ?? []).filter { view in
            let name = view.displayTitle
            if Self.candidates.contains(where: { name.localizedCaseInsensitiveCompare($0) == .orderedSame }) {
                return true
            }
            return name.localizedCaseInsensitiveContains("kids")
        }

        if parents.isNotEmpty {
            allItems = await loadItems(session: userSession)

            // Spotlight pool: highest-rated kids titles that actually have a backdrop, shuffled.
            let candidates = allItems
                .filter { $0.backdropImageTags?.isNotEmpty == true && brunoHeroEligible($0) }
                .sorted { ($0.communityRating ?? 0) > ($1.communityRating ?? 0) }
            heroItems = Array(
                BrunoRNG.shuffled(Array(candidates.prefix(30)), seed: UInt32.random(in: 1 ... UInt32.max)).prefix(5)
            )
        }

        isLoading = false
    }

    /// Merge the kids parent libraries into one item list (mirrors BrunoCombinedLibrary): each parent
    /// is paged to completion (was a single hard limit=400 request per parent), then the whole merge
    /// is deduped by id + sorted by title ONCE. Movies + series in one pass so the filter chips can
    /// re-slice client-side without refetching.
    private func loadItems(session: UserSession) async -> [BaseItemDto] {
        let userID = session.user.id
        var merged: [BaseItemDto] = []
        for parentID in parents.compactMap(\.id) {
            let page = try? await BrunoItemPaging.fetchAll(client: session.client) { startIndex, limit in
                var parameters = Paths.GetItemsParameters()
                parameters.userID = userID
                parameters.parentID = parentID
                parameters.isRecursive = true
                parameters.includeItemTypes = [.movie, .series]
                parameters.enableUserData = true
                // Studios feed the Pixar / Disney filters; overview + genres feed the hero meta.
                parameters.fields = [.overview, .genres, .studios]
                parameters.sortBy = [.name]
                parameters.sortOrder = [.ascending]
                parameters.startIndex = startIndex
                parameters.limit = limit
                return parameters
            }
            if let page { merged.append(contentsOf: page) }
        }

        var seen = Set<String>()
        return merged
            .filter { item in
                guard let id = item.id else { return true }
                return seen.insert(id).inserted
            }
            .sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
    }
}

// MARK: - Studio matching

private extension BaseItemDto {

    /// Whether any of the title's studios' names contain `keyword` (case-insensitive) — matches
    /// "Pixar" / "Pixar Animation Studios", "Walt Disney Pictures" / "Walt Disney Animation", etc.
    func hasStudio(_ keyword: String) -> Bool {
        studios?.contains { $0.name?.localizedCaseInsensitiveContains(keyword) == true } ?? false
    }
}
