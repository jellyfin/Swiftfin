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

    private var searchCancellables = Set<AnyCancellable>()

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

    var noResults: Bool {
        movies.isEmpty &&
            collections.isEmpty &&
            series.isEmpty &&
            episodes.isEmpty &&
            people.isEmpty
    }

    private var searchTextSubject = CurrentValueSubject<String, Never>("")

    override init() {
        super.init()

        getSuggestions()

        searchTextSubject
            .handleEvents(receiveOutput: { _ in self.cancelPreviousSearch() })
            .filter { !$0.isEmpty }
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink(receiveValue: _search)
            .store(in: &cancellables)
    }

    private func cancelPreviousSearch() {
        searchCancellables.forEach { $0.cancel() }
        print(searchCancellables.count)
    }

    func search(with query: String) {
        searchTextSubject.send(query)
    }

    private func _search(with query: String) {
        getItems(with: query, for: .movie, keyPath: \.movies)
        getItems(with: query, for: .boxSet, keyPath: \.collections)
        getItems(with: query, for: .series, keyPath: \.series)
        getItems(with: query, for: .episode, keyPath: \.episodes)
        getPeople(with: query)
    }

    private func getItems(
        with query: String,
        for itemType: BaseItemKind,
        keyPath: ReferenceWritableKeyPath<SearchViewModel, [BaseItemDto]>
    ) {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 20,
            recursive: true,
            searchTerm: query,
            sortOrder: [.ascending],
            fields: ItemFields.allCases,
            includeItemTypes: [itemType],
            sortBy: ["SortName"],
            enableUserData: true,
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

    private func getPeople(with query: String) {
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
