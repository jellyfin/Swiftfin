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

final class IdentifyItemViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case cancelled
        case error(ErrorMessage)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case cancel
        case search(name: String? = nil, originalTitle: String? = nil, year: Int? = nil)
        case update(RemoteSearchResult)
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case searching
        case updating
    }

    @Published
    var item: BaseItemDto
    @Published
    var searchResults: [RemoteSearchResult] = []
    @Published
    var state: State = .content

    private var updateTask: AnyCancellable?
    private var searchTask: AnyCancellable?

    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {

        case .cancel:
            updateTask?.cancel()
            searchTask?.cancel()

            return .content

        case let .search(name, originalTitle, year):
            searchTask?.cancel()

            searchTask = Task {
                do {
                    let newResults = try await self.searchItem(
                        name: name,
                        originalTitle: originalTitle,
                        year: year
                    )

                    await MainActor.run {
                        self.searchResults = newResults
                        self.state = .content
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()
            return .searching

        case let .update(searchResult):
            updateTask?.cancel()

            updateTask = Task {
                do {
                    try await updateItem(searchResult)

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return .updating
        }
    }

    // MARK: - Return Matching Elements (To Be Overridden)

    private func searchItem(
        name: String?,
        originalTitle: String?,
        year: Int?
    ) async throws -> [RemoteSearchResult] {

        guard let itemID = item.id, let itemType = item.type else {
            return []
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

            return response.value

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

            return response.value

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

            return response.value

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

            return response.value

        default:
            return []
        }
    }

    // MARK: - Save Updated Item to Server

    private func updateItem(_ match: RemoteSearchResult) async throws {
        guard let itemID = item.id else { return }

        let request = Paths.applySearchCriteria(itemID: itemID, match)
        _ = try await userSession.client.send(request)

        try await refreshItem()
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.getItem(
            itemID: itemID,
            userID: userSession.user.id
        )
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            Notifications[.itemShouldRefreshMetadata].post(itemID)
        }
    }
}
