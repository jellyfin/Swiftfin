//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

class ItemEditorViewModel<Element: Equatable>: ViewModel, Stateful, Eventful {

    // MARK: - Events

    enum Event: Equatable {
        case updated
        case loaded
        case error(ErrorMessage)
    }

    // MARK: - Actions

    enum Action: Equatable {
        case load
        case search(String)
        case add([Element])
        case remove([Element])
        case reorder([Element])
        case update(BaseItemDto)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case loading
        case searching
        case refreshing
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case content
        case updating
        case error(ErrorMessage)
    }

    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var item: BaseItemDto
    @Published
    var elements: [Element] = []
    @Published
    var matches: [Element] = []
    @Published
    var state: State = .initial

    var trie = Trie<String, Element>()

    private var loadTask: AnyCancellable?
    private var updateTask: AnyCancellable?
    private var searchTask: AnyCancellable?
    private var searchQuery = CurrentValueSubject<String, Never>("")

    private let eventSubject = PassthroughSubject<Event, Never>()

    final var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
    }

    // MARK: - Initializer

    init(item: BaseItemDto) {
        self.item = item

        super.init()

        setupSearchDebounce()
    }

    // MARK: - Setup Debouncing

    private func setupSearchDebounce() {
        searchQuery
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self else { return }
                guard searchTerm.isNotEmpty else { return }

                self.executeSearch(for: searchTerm)
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {
        case .load:
            loadTask?.cancel()

            loadTask = Task { [weak self] in
                guard let self else { return }

                do {
                    await MainActor.run {
                        self.matches = []
                        self.state = .initial
                        _ = self.backgroundStates.insert(.loading)
                    }

                    let allElements = try await self.fetchElements()

                    await MainActor.run {
                        self.elements = allElements
                        self.state = .content
                        self.eventSubject.send(.loaded)

                        _ = self.backgroundStates.remove(.loading)
                    }

                    populateTrie()

                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        _ = self.backgroundStates.remove(.loading)
                    }
                }
            }.asAnyCancellable()

            return state

        case let .search(searchTerm):
            searchQuery.send(searchTerm)
            return state

        case let .add(addItems):
            executeAction {
                try await self.addComponents(addItems)
            }
            return state

        case let .remove(removeItems):
            executeAction {
                try await self.removeComponents(removeItems)
            }
            return state

        case let .reorder(orderedItems):
            executeAction {
                try await self.reorderComponents(orderedItems)
            }
            return state

        case let .update(updateItem):
            executeAction {
                try await self.updateItem(updateItem)
            }
            return state
        }
    }

    // MARK: - Execute Debounced Search

    private func executeSearch(for searchTerm: String) {
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                await MainActor.run {
                    _ = self.backgroundStates.insert(.searching)
                }

                let results = try await self.searchElements(searchTerm)

                await MainActor.run {
                    self.matches = results
                    _ = self.backgroundStates.remove(.searching)
                }
            } catch {
                let apiError = ErrorMessage(error.localizedDescription)
                await MainActor.run {
                    self.state = .error(apiError)
                    _ = self.backgroundStates.remove(.searching)
                }
            }
        }.asAnyCancellable()
    }

    // MARK: - Helper: Execute Task for Add/Remove/Reorder/Update

    private func executeAction(action: @escaping () async throws -> Void) {
        updateTask?.cancel()

        updateTask = Task { [weak self] in
            guard let self else { return }

            do {
                await MainActor.run {
                    self.state = .updating
                }

                try await action()

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
    }

    // MARK: - Save Updated Item to Server

    func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        let request = Paths.updateItem(itemID: itemId, newItem)
        _ = try await userSession.client.send(request)

        try await refreshItem()

        await MainActor.run {
            Notifications[.itemMetadataDidChange].post(newItem)
        }
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        await MainActor.run {
            _ = self.backgroundStates.insert(.refreshing)
        }

        let request = Paths.getItem(
            itemID: itemId,
            userID: userSession.user.id
        )
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = self.backgroundStates.remove(.refreshing)
        }
    }

    // MARK: - Populate the Trie

    func populateTrie() {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Add Element Component to Item (To Be Overridden)

    func addComponents(_ components: [Element]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Remove Element Component from Item (To Be Overridden)

    func removeComponents(_ components: [Element]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Reorder Elements (To Be Overridden)

    // TODO: should instead move to an index-based self insertion
    //       instead of replacement
    func reorderComponents(_ tags: [Element]) async throws {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Fetch All Possible Elements (To Be Overridden)

    func fetchElements() async throws -> [Element] {
        fatalError("This method should be overridden in subclasses")
    }

    // MARK: - Return Matching Elements (To Be Overridden)

    func searchElements(_ searchTerm: String) async throws -> [Element] {
        trie.search(prefix: searchTerm.localizedLowercase)
    }
}
