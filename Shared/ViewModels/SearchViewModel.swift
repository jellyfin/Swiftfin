//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

final class SearchViewModel: ViewModel {

    @Published
    var movies: [BaseItemDto] = []
    @Published
    var collections: [BaseItemDto] = []
    @Published
    var series: [BaseItemDto] = []
    @Published
    var episodes: [BaseItemDto] = []
    @Published
    var people: [BaseItemDto] = []
    @Published
    var suggestions: [BaseItemDto] = []

    let filterViewModel: FilterViewModel
    private var searchTextSubject = CurrentValueSubject<String, Never>("")
    private var searchCancellables = Set<AnyCancellable>()

    var noResults: Bool {
        movies.isEmpty &&
            collections.isEmpty &&
            series.isEmpty &&
            episodes.isEmpty &&
            people.isEmpty
    }

    override init() {
        self.filterViewModel = .init(parent: nil, currentFilters: .init())
        super.init()

        getSuggestions()

        searchTextSubject
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { newSearch in

                if newSearch.isEmpty {
                    self.movies = []
                    self.collections = []
                    self.series = []
                    self.episodes = []
                    self.people = []

                    return
                }

                self._search(with: newSearch, filters: self.filterViewModel.currentFilters)
            }
            .store(in: &cancellables)

        filterViewModel.$currentFilters
            .sink { newFilters in
                self._search(with: self.searchTextSubject.value, filters: newFilters)
            }
            .store(in: &cancellables)
    }

    func search(with query: String) {
        searchTextSubject.send(query)
    }

    private func _search(with query: String, filters: ItemFilters) {
        getItems(for: query, with: filters, type: .movie, keyPath: \.movies)
        getItems(for: query, with: filters, type: .boxSet, keyPath: \.collections)
        getItems(for: query, with: filters, type: .series, keyPath: \.series)
        getItems(for: query, with: filters, type: .episode, keyPath: \.episodes)
        getPeople(for: query, with: filters)
    }

    private func getItems(
        for query: String,
        with filters: ItemFilters,
        type itemType: BaseItemKind,
        keyPath: ReferenceWritableKeyPath<SearchViewModel, [BaseItemDto]>
    ) {
        let genreIDs = filters.genres.compactMap(\.id)
        let sortBy = filters.sortBy.map(\.filterName)
        let sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
        let itemFilters: [ItemFilter] = filters.filters.compactMap { .init(rawValue: $0.filterName) }

        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                limit: 20,
                isRecursive: true,
                searchTerm: query,
                sortOrder: sortOrder,
                fields: ItemFields.allCases,
                includeItemTypes: [itemType],
                filters: itemFilters,
                sortBy: sortBy,
                enableUserData: true,
                genreIDs: genreIDs,
                enableImages: true
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                self[keyPath: keyPath] = response.value.items ?? []
            }
        }
    }

    private func getPeople(for query: String?, with filters: ItemFilters) {
        guard !filters.hasFilters else {
            self.people = []
            return
        }

        Task {
            let parameters = Paths.GetPersonsParameters(
                limit: 20,
                searchTerm: query
            )
            let request = Paths.getPersons(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                people = response.value.items ?? []
            }
        }
    }

    private func getSuggestions() {
        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                limit: 10,
                isRecursive: true,
                includeItemTypes: [.movie, .series],
                sortBy: ["IsFavoriteOrLiked", "Random"],
                imageTypeLimit: 0,
                enableTotalRecordCount: false,
                enableImages: false
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                suggestions = response.value.items ?? []
            }
        }
    }
}
