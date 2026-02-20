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
import OrderedCollections
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
    private(set) var items: [BaseItemKind: [BaseItemDto]] = [:]
    @Published
    private(set) var suggestions: [BaseItemDto] = []

    private var searchQuery: CurrentValueSubject<String, Never> = .init("")

    let filterViewModel: FilterViewModel

    var hasNoResults: Bool {
        items.values.allSatisfy(\.isEmpty)
    }

    var canSearch: Bool {
        searchQuery.value.isNotEmpty || filterViewModel.currentFilters.hasQueryableFilters
    }

    // MARK: init

    init(filterViewModel: FilterViewModel = .init()) {
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

            // Base items
            let retrievingItemTypes: [BaseItemKind] = [
                .boxSet,
                .episode,
                .movie,
                .musicArtist,
                .musicVideo,
                .liveTvProgram,
                .series,
                .tvChannel,
                .video,
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

        var parameters = Paths.GetItemsByUserIDParameters()
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
        parameters.sortBy = filters.sortBy.map(\.rawValue)
        parameters.sortOrder = filters.sortOrder
        parameters.tags = filters.tags.map(\.value)
        parameters.years = filters.years.map(\.intValue)

        if filters.letter.first?.value == "#" {
            parameters.nameLessThan = "A"
        } else {
            parameters.nameStartsWith = filters.letter
                .map(\.value)
                .filter { $0 != "#" }
                .first
        }

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func _getPeople(query: String) async throws -> [BaseItemDto] {

        var parameters = Paths.GetPersonsParameters()
        parameters.limit = 20
        parameters.searchTerm = query

        let request = Paths.getPersons(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    // MARK: suggestions

    @Function(\Action.Cases.getSuggestions)
    private func _getSuggestions() async throws {

        filterViewModel.send(.getQueryFilters)

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
