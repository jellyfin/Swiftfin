//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension Container {

    /// A single shared, session-scoped `SearchViewModel`. Sharing it lets the app **prefetch** the
    /// search landing data — the suggestion shelf and the filter metadata (genres / tags / years) — in
    /// the background at launch (see `HomeView`) into the SAME instance the Search tab later displays,
    /// so landing on Search shows suggestions immediately instead of building + fetching on first
    /// appear. `.scope(.session)` keeps one instance for the app session; its network calls always use
    /// the current `userSession`. The scope is NOT cleared on sign-out, so the view model wipes itself
    /// on a session change (see `observeSessionChangesIfNeeded`).
    var searchViewModel: Factory<SearchViewModel> {
        self { @MainActor in SearchViewModel(filterViewModel: FilterViewModel()) }
            .scope(.session)
    }
}

@MainActor
@Stateful
final class SearchViewModel: ViewModel {

    @CasePathable
    enum Action {
        case getSuggestions
        case search(query: String)
        case actuallySearch(query: String)

        var transition: Transition {
            switch self {
            case .getSuggestions:
                .none
            case let .search(query):
                query.isEmpty ? .to(.initial) : .to(.searching)
            case .actuallySearch:
                .to(.searching, then: .initial)
                    .onRepeat(.cancel)
            }
        }
    }

    enum State {
        case error
        case initial
        case searching
    }

    @Published
    private(set) var items: [BaseItemKind: [BaseItemDto]] = [:]
    @Published
    private(set) var suggestions: [BaseItemDto] = []

    /// True while the suggestion shelf is being fetched AND nothing is shown yet — drives the Search
    /// page's loading spinner. Kept separate from `state` (which tracks active QUERY searches) so the
    /// suggestion load never gates the search bar / keyboard.
    @Published
    private(set) var isLoadingSuggestions = false

    private var searchQuery: CurrentValueSubject<String, Never> = .init("")

    // Background launch warm-up bookkeeping (see `prefetchIfNeeded`).
    private var hasPrefetched = false
    private var observingSession = false

    let filterViewModel: FilterViewModel

    var hasNoResults: Bool {
        items.values.allSatisfy(\.isEmpty)
    }

    var canSearch: Bool {
        searchQuery.value.isNotEmpty || filterViewModel.currentFilters.hasQueryableFilters
    }

    // MARK: init

    @MainActor
    init(filterViewModel: FilterViewModel) {
        self.filterViewModel = filterViewModel
        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }

                actuallySearch(query: query)
            }
            .store(in: &cancellables)

        filterViewModel.$currentFilters
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }

                actuallySearch(query: searchQuery.value)
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        searchQuery.value = query

        await cancel()
    }

    @Function(\Action.Cases.actuallySearch)
    private func _actuallySearch(_ query: String) async throws {

        guard self.canSearch else {
            items.removeAll()
            return
        }

        let newItems = try await withThrowingTaskGroup(
            of: (BaseItemKind, [BaseItemDto]).self,
            returning: [BaseItemKind: [BaseItemDto]].self
        ) { group in

            // Only the categories the rebuilt search surfaces: Movies, Shows, Episodes (+ People below).
            // Trimmed from the old 9-type fan-out (collections/music/channels/programs/videos) so each
            // search fires far fewer concurrent requests — the main cause of the search feeling sluggish.
            let retrievingItemTypes: [BaseItemKind] = [
                .movie,
                .series,
                .episode,
            ]

            for type in retrievingItemTypes {
                group.addTask {
                    let items = try await self._getItems(query: query, itemType: type)
                    return (type, items)
                }
            }

            // People
            group.addTask {
                let items = try await self._getPeople(query: query)
                return (BaseItemKind.person, items)
            }

            var result: [BaseItemKind: [BaseItemDto]] = [:]

            while let items = try await group.next() {
                if items.1.isNotEmpty {
                    result[items.0] = items.1
                }
            }

            return result
        }

        guard !Task.isCancelled else { return }
        self.items = newItems
    }

    private func _getItems(query: String, itemType: BaseItemKind) async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [itemType]
        parameters.isRecursive = true
        parameters.limit = 20
        parameters.searchTerm = query

        // Filters
        let filters = filterViewModel.currentFilters
        parameters.filters = filters.traits
        parameters.genres = filters.genres.map(\.value)
        parameters.sortBy = filters.sortBy
        parameters.sortOrder = filters.sortOrder
        parameters.tags = filters.tags.map(\.value)
        parameters.years = filters.years.map(\.intValue)

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .first(where: { $0 != "#" })
        }

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        // Only show results that actually have poster artwork — drop the art-less "clutter" entries.
        return (response.value.items ?? []).filter(Self.hasPosterArtwork)
    }

    private func _getPeople(query: String) async throws -> [BaseItemDto] {

        var parameters = Paths.GetPersonsParameters()
        parameters.limit = 20
        parameters.searchTerm = query

        let request = Paths.getPersons(parameters: parameters)
        let response = try await send(request)

        // Actors are filtered the same way — only those with a headshot photo are shown.
        return (response.value.items ?? []).filter(Self.hasPosterArtwork)
    }

    /// True when the item has its own primary image (poster / still / headshot). Used to hide art-less
    /// results from every search row.
    private static func hasPosterArtwork(_ item: BaseItemDto) -> Bool {
        (item.imageTags?[ImageType.primary.rawValue]?.isEmpty == false)
    }

    // MARK: suggestions

    @Function(\Action.Cases.getSuggestions)
    private func _getSuggestions() async throws {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }

        // Prefer the SAME curated set the home spotlight features — randomly sampled. It's a small,
        // relevant set, so this avoids the expensive whole-library `ItemSortBy.random` server query (slow
        // on large libraries). When that curated set isn't present, fall back to a whole-library random
        // query. (How the curated set is resolved lives in `GuamaFlixSpotlightSuggestions`.)
        let spotlightSuggestions = await GuamaFlixSpotlightSuggestions.sampledItems()
        self.suggestions = try await spotlightSuggestions.isNotEmpty
            ? spotlightSuggestions
            : randomLibrarySuggestions()

        // Load filter options AFTER suggestions, off the critical path: opening Search no longer waits on
        // the heavier filter-metadata fetch (genres / tags / years / studios). The filter UI only needs
        // these once the user actually opens the filter drawer.
        Task { await filterViewModel.getQueryFilters() }
    }

    /// The whole-library fallback: a random Movies/Shows query (used when no spotlight playlist exists).
    private func randomLibrarySuggestions(limit: Int = 10) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = limit
        parameters.sortBy = [ItemSortBy.random]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return (response.value.items ?? []).filter(Self.hasPosterArtwork)
    }

    // MARK: prefetch

    /// One-shot background warm-up at app launch: fetches the suggestion shelf (and, off its critical
    /// path, the filter metadata) **once** so landing on the Search tab shows suggestions immediately
    /// instead of a first-appear build + network round-trip. Idempotent and silent — if it fails, the
    /// tab simply loads suggestions normally when opened.
    func prefetchIfNeeded() {
        observeSessionChangesIfNeeded()
        guard !hasPrefetched else { return }
        hasPrefetched = true

        getSuggestions()
    }

    /// This view model is a shared, session-scoped singleton (so it can be prefetched at launch), and
    /// that scope is NOT cleared on sign-out. Without this, after an account/server switch the previous
    /// user's suggestions/results would linger and could briefly be shown to the next user. So we wipe
    /// everything whenever the signed-in session changes and let it re-prefetch fresh.
    private func observeSessionChangesIfNeeded() {
        guard !observingSession else { return }
        observingSession = true

        Notifications[.didChangeUserSession]
            .publisher
            .sink { [weak self] _ in
                Task { @MainActor in self?.reset() }
            }
            .store(in: &cancellables)
    }

    private func reset() {
        hasPrefetched = false
        items.removeAll()
        suggestions.removeAll()
        isLoadingSuggestions = false
        searchQuery.value = ""
    }
}
