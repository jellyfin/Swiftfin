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

class ItemInfoViewModel<SearchInfo: Equatable>: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case search(SearchInfo)
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

        case let .search(searchInfo):
            searchTask?.cancel()

            searchTask = Task { [weak self] in
                guard let self else { return }

                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.searching)
                    }

                    let allElements = try await self.searchItem(searchInfo)

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

    func searchItem(_ searchInfo: SearchInfo) async throws -> [RemoteSearchResult] {
        fatalError("This method should be overridden in subclasses")
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
