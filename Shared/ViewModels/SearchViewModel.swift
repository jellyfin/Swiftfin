//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

final class SearchViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action {
        case error(JellyfinAPIError)
        case getSuggestions
        case search(query: String)
    }

    // MARK: State

    enum State: Equatable {
        case error(JellyfinAPIError)
        case initial
        case items
        case searching
    }

    @Published
    var collections: [BaseItemDto] = []
    @Published
    var episodes: [BaseItemDto] = []
    @Published
    var movies: [BaseItemDto] = []
    @Published
    var people: [BaseItemDto] = []
    @Published
    var series: [BaseItemDto] = []
    @Published
    var suggestions: [BaseItemDto] = []

    @Published
    var state: State = .initial

    private var searchTask: AnyCancellable?
    private var searchQuery: PassthroughSubject<String, Never> = .init()

    let filterViewModel: FilterViewModel

    var hasNoResults: Bool {
        collections.isEmpty &&
            episodes.isEmpty &&
            movies.isEmpty &&
            people.isEmpty &&
            series.isEmpty
    }

    override init() {
        self.filterViewModel = .init()
        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }

                self.searchTask?.cancel()
                self.search(query: query)
            }
            .store(in: &cancellables)

//        filterViewModel.$currentFilters
//            .sink { newFilters in
//                guard self.searchTextSubject.value.isNotEmpty else { return }
//                self._search(with: self.searchTextSubject.value, filters: newFilters)
//            }
//            .store(in: &cancellables)
    }

    // MARK: respond

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        case let .search(query):
            if query.isEmpty {
                searchTask?.cancel()
                searchTask = nil
                return .initial
            } else {
                searchQuery.send(query)
                return .searching
            }
        case .getSuggestions:
            Task {
                let suggestions = try await getSuggestions()

                await MainActor.run {
                    self.suggestions = suggestions
                }
            }
            .asAnyCancellable()
            .store(in: &cancellables)

            return state
        }
    }

    private func search(query: String) {
        searchTask = Task {

            do {

                try await Task.sleep(nanoseconds: 3_000_000_000)

                let items = try await withThrowingTaskGroup(
                    of: (BaseItemKind, [BaseItemDto]).self,
                    returning: [BaseItemKind: [BaseItemDto]].self
                ) { group in

                    // Base items
                    let retrievingItemTypes: [BaseItemKind] = [
                        .boxSet,
                        .episode,
                        .movie,
                        .series,
                    ]

                    for type in retrievingItemTypes {
                        group.addTask {
                            let items = try await self.getItems(query: query, itemType: type)
                            return (type, items)
                        }
                    }

                    // People
                    group.addTask {
                        let items = try await self.getPeople(query: query)
                        return (BaseItemKind.person, items)
                    }

                    var result: [BaseItemKind: [BaseItemDto]] = [:]

                    while let items = try await group.next() {
                        result[items.0] = items.1
                    }

                    return result
                }

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.collections = items[.boxSet] ?? []
                    self.episodes = items[.episode] ?? []
                    self.movies = items[.movie] ?? []
                    self.people = items[.person] ?? []
                    self.series = items[.series] ?? []

                    self.state = .items
                }
            } catch {

                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.send(.error(.init(error.localizedDescription)))
                }
            }
        }
        .asAnyCancellable()
    }

    private func getItems(query: String, itemType: BaseItemKind) async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.MinimumFields
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

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getPeople(query: String) async throws -> [BaseItemDto] {

        var parameters = Paths.GetPersonsParameters()
        parameters.limit = 20
        parameters.searchTerm = query

        let request = Paths.getPersons(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getSuggestions() async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.includeItemTypes = [.movie, .series]
        parameters.isRecursive = true
        parameters.limit = 10
        parameters.sortBy = [ItemSortBy.random.rawValue]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
