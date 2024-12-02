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
import OrderedCollections

class ItemEditorViewModel<Element: Equatable>: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case refresh
        case add([Element])
        case remove([Element])
        case update(BaseItemDto)
        case getSuggestions(String)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case refreshing
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case error(JellyfinAPIError)
        case updating
    }

    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    @Published
    var item: BaseItemDto
    @Published
    var elements: [Element] = []
    @Published
    var suggestions: [Element] = []

    @Published
    var state: State = .initial

    private var task: AnyCancellable?
    private let eventSubject = PassthroughSubject<Event, Never>()

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Init

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    let allElements = try await self.fetchElements()

                    await MainActor.run {
                        self.elements = allElements
                        self.state = .initial
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .getSuggestions(searchTerm):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    let matches = try await self.fetchSuggestions(searchTerm)

                    await MainActor.run {
                        self.suggestions = matches
                        self.state = .initial
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .add(addItems):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run { self.state = .updating }

                    try await self.addComponents(addItems)

                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .remove(removeItems):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run { self.state = .updating }

                    try await self.removeComponents(removeItems)

                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .update(updateItem):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run { self.state = .updating }

                    try await self.updateItem(updateItem)

                    await MainActor.run {
                        self.state = .initial
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - Save Updated Item to Server

    func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        let request = Paths.updateItem(itemID: itemId, newItem)
        _ = try await userSession.client.send(request)

        try await refreshItem()

        await MainActor.run {
            Notifications[.itemMetadataDidChange].post(object: newItem)
        }
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.append(.refreshing)
        }

        let request = Paths.getItem(userID: userSession.user.id, itemID: itemId)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = backgroundStates.remove(.refreshing)
        }
    }

    // MARK: - Add Element Component to Item (To Be Overridden)

    func addComponents(_ components: [Element]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Remove Element Component from Item (To Be Overridden)

    func removeComponents(_ components: [Element]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Fetch All Possible Elements (To Be Overridden)

    func fetchElements() async throws -> [Element] {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Get Item Suggestions (To Be Overridden)

    func fetchSuggestions(_ searchTerm: String) async throws -> [Element] {
        fatalError("This method should be overridden in subclasses")
    }
}
