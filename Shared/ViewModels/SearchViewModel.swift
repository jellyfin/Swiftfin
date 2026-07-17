//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
@Stateful
final class SearchViewModel: ViewModel {

    @CasePathable
    enum Action {
        case getSuggestions
        case search(query: String)
        case _actuallySearch

        var transition: Transition {
            switch self {
            case .getSuggestions:
                .none
            case let .search(query):
                query.isEmpty ? .to(.initial) : .to(.searching)
            case ._actuallySearch:
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
    private(set) var suggestions: [BaseItemDto] = []

    let itemContentGroupViewModel: ContentGroupViewModel<SearchContentGroupProvider>

    var filterViewModel: FilterViewModel {
        itemContentGroupViewModel.provider.filterViewModel
    }

    var isEmpty: Bool {
        itemContentGroupViewModel.groups.isEmpty
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    var canSearch: Bool {
        filterViewModel.currentFilters.hasQueryableFilters
    }

    override init() {
        self.itemContentGroupViewModel = .init(provider: .init())

        super.init()

        observeFilters()
    }

    private func observeFilters() {
        filterViewModel.$currentFilters
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?._actuallySearch()
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        filterViewModel.currentFilters.query = query.nilIfBlank

        await cancel()
    }

    @Function(\Action.Cases._actuallySearch)
    private func __actuallySearch() async throws {

        guard canSearch else { return }

        let filters = filterViewModel.currentFilters

        itemContentGroupViewModel.provider.environment.filters = filters

        await itemContentGroupViewModel.refresh()
    }

    @Function(\Action.Cases.getSuggestions)
    private func _getSuggestions() async throws {

        await filterViewModel.getQueryFilters()

        var parameters = Paths.GetItemsParameters()
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 10
        parameters.sortBy = [ItemSortBy.random]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        self.suggestions = response.value.items ?? []
    }
}
