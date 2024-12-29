//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI
import OrderedCollections

class ItemIdentifyViewModel: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case cancelled
        case error(JellyfinAPIError)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case cancel
        case search(name: String? = nil, originalTitle: String? = nil, year: Int? = nil)
        case update(RemoteSearchResult)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case searching
        case refreshing
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case updating
    }

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    var item: BaseItemDto
    @Published
    var searchResults: [RemoteSearchResult] = []
    @Published
    var state: State = .initial

    private var updateTask: AnyCancellable?
    private var searchTask: AnyCancellable?

    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
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

            self.backgroundStates = []
            self.state = .initial

            return state

        case let .search(name, originalTitle, year):
            searchTask?.cancel()

            searchTask = Task { [weak self] in
                guard let self else { return }

                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.searching)
                    }

                    let allElements = try await self.searchItem(
                        name: name,
                        originalTitle: originalTitle,
                        year: year
                    )

                    await MainActor.run {
                        self.searchResults = allElements
                        _ = self.backgroundStates.remove(.searching)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()
            return state

        case let .update(searchResult):
            updateTask?.cancel()

            updateTask = Task { [weak self] in
                guard let self else { return }

                do {
                    await MainActor.run {
                        self.state = .updating
                    }

                    try await updateItem(searchResult)

                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - Return Matching Elements (To Be Overridden)

    private func searchItem(
        name: String?,
        originalTitle: String?,
        year: Int?
    ) async throws -> [RemoteSearchResult] {

        guard let itemId = item.id, let itemType = item.type else {
            return []
        }

        switch itemType {
        case .boxSet:
            let parameters = BoxSetInfoRemoteSearchQuery(
                itemID: itemId,
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
                itemID: itemId,
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
                itemID: itemId,
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
                itemID: itemId,
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
        guard let itemId = item.id else { return }

        let request = Paths.applySearchCriteria(itemID: itemId, match)
        _ = try await userSession.client.send(request)

        try await refreshItem()
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        await MainActor.run {
            _ = self.backgroundStates.append(.refreshing)
        }

        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = self.backgroundStates.remove(.refreshing)

            Notifications[.itemMetadataDidChange].post(item)
        }
    }
}
