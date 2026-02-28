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
        case _actuallySearch(query: String)

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

    let filterViewModel: FilterViewModel
    let itemContentGroupViewModel: ContentGroupViewModel<SearchContentGroupProvider>

    private let searchQuery: CurrentValueSubject<String, Never> = .init("")

    var isEmpty: Bool {
        func extract(_ group: some ContentGroup) -> Bool {
            func inner(_ vm: some __PagingLibaryViewModel) -> Bool {
                vm.elements.isEmpty
            }

            if let libaryViewModel = group.viewModel as? any __PagingLibaryViewModel {
                return inner(libaryViewModel)
            } else {
                return true
            }
        }

        return itemContentGroupViewModel.groups
            .map { extract($0) }
            .allSatisfy(\.self)
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    var canSearch: Bool {
        searchQuery.value.isNotEmpty || filterViewModel.currentFilters.hasQueryableFilters
    }

    init(filterViewModel: FilterViewModel? = nil) {
        let filterViewModel = filterViewModel ?? .init()

        self.filterViewModel = filterViewModel
        self.itemContentGroupViewModel = .init(provider: .init())

        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?._actuallySearch(query: query)
            }
            .store(in: &cancellables)

        filterViewModel.$currentFilters
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let query = self?.searchQuery.value else { return }
                self?._actuallySearch(query: query)
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: String) async throws {
        searchQuery.value = query

        await cancel()
    }

    @Function(\Action.Cases._actuallySearch)
    private func __actuallySearch(_ query: String) async throws {

        guard canSearch else { return }

        func inner<VM: __PagingLibaryViewModel>(_ vm: VM) where VM._PagingLibrary == ItemLibrary {
            var filters = vm.environment.filters
            filters.query = query

            vm.environment = .init(
                grouping: vm.environment.grouping,
                filters: filters,
                fields: nil
            )
        }

        var filters = filterViewModel.currentFilters
        filters.query = query

        itemContentGroupViewModel.provider.environment.filters = filters

        await itemContentGroupViewModel.refresh()
    }

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
