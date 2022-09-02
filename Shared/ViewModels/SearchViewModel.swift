//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
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
            .handleEvents(receiveOutput: { _ in self.cancelPreviousSearch() })
            .filter { !$0.isEmpty }
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink { newSearch in
                self._search(with: newSearch, filters: self.filterViewModel.currentFilters)
            }
            .store(in: &cancellables)

        filterViewModel.$currentFilters
            .sink { newFilters in
                self._search(with: self.searchTextSubject.value, filters: newFilters)
            }
            .store(in: &cancellables)
    }

    private func cancelPreviousSearch() {
        searchCancellables.forEach { $0.cancel() }
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
        let sortBy: [String] = filters.sortBy.map(\.filterName)
        let sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
        let itemFilters: [ItemFilter] = filters.filters.compactMap { .init(rawValue: $0.filterName) }
        let tags: [String] = filters.tags.map(\.filterName)

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 20,
            recursive: true,
            searchTerm: query,
            sortOrder: sortOrder,
            fields: ItemFields.allCases,
            includeItemTypes: [itemType],
            filters: itemFilters,
            sortBy: sortBy,
            tags: tags,
            enableUserData: true,
            genreIds: genreIDs,
            enableImages: true
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            self?[keyPath: keyPath] = response.items ?? []
        })
        .store(in: &searchCancellables)
    }

    private func getPeople(for query: String?, with filters: ItemFilters) {
        guard !filters.hasFilters else {
            self.people = []
            return
        }

        PersonsAPI.getPersons(
            limit: 20,
            searchTerm: query
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            self?.people = response.items ?? []
        })
        .store(in: &searchCancellables)
    }

    private func getSuggestions() {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 10,
            recursive: true,
            includeItemTypes: [.movie, .series],
            sortBy: ["IsFavoriteOrLiked", "Random"],
            imageTypeLimit: 0,
            enableTotalRecordCount: false,
            enableImages: false
        )
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            self?.suggestions = response.items ?? []
        })
        .store(in: &cancellables)
    }
}
