//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
    private(set) var suggestions: [BaseItemDto] = []

    let itemContentGroupViewModel: ContentGroupViewModel<SearchContentGroupProvider>

    private var searchQuery: CurrentValueSubject<String, Never> = .init("")

    let filterViewModel: FilterViewModel

    var hasNoResults: Bool {
        itemContentGroupViewModel.sections
            .allSatisfy { _, _ in
                @MainActor
                func isEmpty(_ vm: some __PagingLibaryViewModel) -> Bool {
                    vm.elements.isEmpty
                }

//                return isEmpty(viewModel)
                return false
            }
    }

    var canSearch: Bool {
        searchQuery.value.isNotEmpty || filterViewModel.currentFilters.hasQueryableFilters
    }

    // MARK: init

    init(filterViewModel: FilterViewModel? = nil) {
        let filterViewModel = filterViewModel ?? .init()

        self.filterViewModel = filterViewModel

        self.itemContentGroupViewModel = .init(provider: .init())

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
//            items.removeAll()
            return
        }

        func inner<VM: __PagingLibaryViewModel>(_ vm: VM) where VM._PagingLibrary == PagingItemLibrary {
            var filters = vm.environment.filters
            filters.query = query

            vm.environment = .init(
                grouping: vm.environment.grouping,
                filters: filters
            )

            print(vm.environment)
        }

//        for (viewModel, _) in itemContentGroupViewModel.sections {
//            if let library = viewModel.library as? PagingItemLibrary {
//                library.filterViewModel?.currentFilters.query = query
//            }
//        }

        var filters = filterViewModel.currentFilters
        filters.query = query

        itemContentGroupViewModel.provider.environment.filters = filters

        await itemContentGroupViewModel.refresh()
    }

    // MARK: suggestions

    @Function(\Action.Cases.getSuggestions)
    private func _getSuggestions() async throws {

        async let _ = filterViewModel.getQueryFilters()

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 10
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        self.suggestions = response.value.items ?? []
    }
}
