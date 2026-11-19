//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@Observable
@StatefulObservable
final class SearchViewModel: ViewModel {

    @CasePathable
    enum Action {

        case getSuggestions
        case search(filters: ItemFilterCollection)

        var transition: Transition {
            switch self {
            case .getSuggestions:
                .none
            case let .search(filters):
                .to(filters.hasQueryableFilters ? .searching : .initial, then: .initial)
                    .onRepeat(.cancel)
            }
        }
    }

    enum State {

        case error
        case initial
        case searching
    }

    let filterViewModel = FilterViewModel()

    private(set) var itemContentGroupViewModel: ContentGroupViewModel<SearchContentGroupProvider>

    var query = "" {
        didSet {
            let normalizedQuery = query.nilIfBlank
            guard normalizedQuery != filterViewModel.currentFilters.query else { return }

            core.cancel(action: \.search)
            filterViewModel.currentFilters.query = normalizedQuery
        }
    }

    private var suggestionsStorage = ValueBox<[ItemEntry]>(value: [])

    var canSearch: Bool {
        filterViewModel.currentFilters.hasQueryableFilters
    }

    var isEmpty: Bool {
        itemContentGroupViewModel.groups.isEmpty
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    var suggestions: [BaseItemDto] {
        suggestionsStorage.value.compactMap(\.value)
    }

    override init() {
        self.itemContentGroupViewModel = .init(provider: .init())

        super.init()

        DebouncedObservation.observe(
            { [filterViewModel] in
                filterViewModel.currentFilters
            },
            for: .milliseconds(500),
            onChange: { [weak self] filters in
                self?.filtersDidChange(filters)
            }
        ) { [weak self] filters in
            guard filters.hasQueryableFilters else { return }

            self?.search(filters: filters)
        }
        .store(in: &cancellables)
    }

    private func filtersDidChange(_ filters: ItemFilterCollection) {
        if query.nilIfBlank != filters.query {
            query = filters.query ?? ""
        }

        core.cancel(action: \.search)

        if !filters.hasQueryableFilters {
            search(filters: filters)
        }
    }

    @Function(\Action.Cases.search)
    private func _search(_ filters: ItemFilterCollection) async throws {
        guard filters.hasQueryableFilters, filters == filterViewModel.currentFilters else { return }

        let results = ContentGroupViewModel(provider: SearchContentGroupProvider(environment: .init(filters: filters)))
        itemContentGroupViewModel = results
        await results.refresh()

        try Task.checkCancellation()
        guard filters == filterViewModel.currentFilters else { throw CancellationError() }

        if results.state == .error, let error = results.error {
            throw error
        }
    }

    @Function(\Action.Cases.getSuggestions)
    private func _getSuggestions() async throws {
        await filterViewModel.getQueryFilters()

        var parameters = Paths.GetItemsParameters()
        parameters.fields = PosterSubtitleField.itemFields
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 10
        parameters.sortBy = [ItemSortBy.random]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        try Task.checkCancellation()

        withExtendedLifetime(response.items) {
            suggestionsStorage = .init(value: (response.value.items ?? []).map(ItemEntry.resolve))
        }
    }
}
