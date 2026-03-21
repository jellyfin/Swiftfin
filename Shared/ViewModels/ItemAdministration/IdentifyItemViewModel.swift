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

    @CasePathable
    enum Action {
        case search(name: String?, originalTitle: String?, year: Int?)
        case update(RemoteSearchResult)

        var transition: Transition {
            switch self {
            case .search:
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

    struct SearchParameters: Equatable {
        var name: String?
        var originalTitle: String?
        var year: Int?
    }

    @Published
    var item: BaseItemDto

    @Published
    var searchResults: [RemoteSearchResult] = []

    var searchParameters = CurrentValueSubject<SearchParameters, Never>(.init())

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        searchParameters
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] parameters in
                guard let self else { return }
                self.search(
                    name: parameters.name,
                    originalTitle: parameters.originalTitle,
                    year: parameters.year
                )
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.search)
    private func _search(_ name: String?, _ originalTitle: String?, _ year: Int?) async throws {
        guard let itemID = item.id, let itemType = item.type else {
            searchResults = []
            return
        }

        switch itemType {
        case .boxSet:
            let parameters = BoxSetInfoRemoteSearchQuery(
                itemID: itemID,
                searchInfo: BoxSetInfo(
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
                searchInfo: MovieInfo(
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
                searchInfo: PersonLookupInfo(
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
                searchInfo: SeriesInfo(
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

        item = try await item.getFullItem(userSession: userSession, sendNotification: true)

        events.send(.updated)
    }
}
