//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class IdentifyItemViewModel: ViewModel {

    struct SearchQuery: Equatable {
        var name: String?
        var originalTitle: String?
        var year: Int?

        var isEmpty: Bool {
            name?.isEmpty != false && originalTitle?.isEmpty != false && year == nil
        }

        var isNotEmpty: Bool {
            !isEmpty
        }
    }

    @CasePathable
    enum Action {
        case _actuallySearch(query: SearchQuery)
        case search(query: SearchQuery)
        case update(RemoteSearchResult)

        var transition: Transition {
            switch self {
            case ._actuallySearch, .search:
                .background(.searching)
            case .update:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case searching
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case error
    }

    @Published
    private(set) var searchResults: [RemoteSearchResult] = []

    let item: BaseItemDto
    private var searchQuery = CurrentValueSubject<SearchQuery, Never>(.init())

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?._actuallySearch(query: query)
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ query: SearchQuery) async throws {
        searchQuery.send(query)

        await cancel()
    }

    @Function(\Action.Cases._actuallySearch)
    private func __actuallySearch(_ query: SearchQuery) async throws {

        guard query.isNotEmpty else {
            searchResults = []
            return
        }

        let name = query.name
        let originalTitle = query.originalTitle
        let year = query.year

        guard let itemID = item.id, let itemType = item.type else {
            searchResults = []
            return
        }

        switch itemType {
        case .boxSet:
            let parameters = BoxSetInfoRemoteSearchQuery(
                itemID: itemID,
                searchInfo: .init(
                    name: name,
                    originalTitle: originalTitle,
                    year: year
                )
            )
            let request = Paths.getBoxSetRemoteSearchResults(parameters)
            let response = try await userSession.client.send(request)

            searchResults = response.value

        case .movie:
            let parameters = MovieInfoRemoteSearchQuery(
                itemID: itemID,
                searchInfo: .init(
                    name: name,
                    originalTitle: originalTitle,
                    year: year
                )
            )
            let request = Paths.getMovieRemoteSearchResults(parameters)
            let response = try await userSession.client.send(request)

            searchResults = response.value

        case .person:
            let parameters = PersonLookupInfoRemoteSearchQuery(
                itemID: itemID,
                searchInfo: .init(
                    name: name,
                    originalTitle: originalTitle,
                    year: year
                )
            )
            let request = Paths.getPersonRemoteSearchResults(parameters)
            let response = try await userSession.client.send(request)

            searchResults = response.value

        case .series:
            let parameters = SeriesInfoRemoteSearchQuery(
                itemID: itemID,
                searchInfo: .init(
                    name: name,
                    originalTitle: originalTitle,
                    year: year
                )
            )
            let request = Paths.getSeriesRemoteSearchResults(parameters)
            let response = try await userSession.client.send(request)

            searchResults = response.value

        default:
            searchResults = []
        }
    }

    @Function(\Action.Cases.update)
    private func _update(_ searchResult: RemoteSearchResult) async throws {
        guard let itemID = item.id else { return }

        let request = Paths.applySearchCriteria(itemID: itemID, searchResult)
        _ = try await userSession.client.send(request)

        _ = try await item.getFullItem(userSession: userSession, sendNotification: true)

        events.send(.updated)
    }
}
