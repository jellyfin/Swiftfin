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

@MainActor
@Stateful
class ItemEditorViewModel<Element: Equatable>: ViewModel {

    @CasePathable
    enum Action {
        case search(String)
        case actuallySearch(String)
        case add([Element])
        case remove([Element])
        case reorder([Element])
        case update(BaseItemDto)

        var transition: Transition {
            switch self {
            case let .search(query):
                query.isEmpty ? .to(.initial) : .background(.searching)
            case .actuallySearch:
                .background(.searching)
            case .add, .remove, .reorder, .update:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
        case searching
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case error
    }

    // MARK: - Published Properties

    @Published
    var item: BaseItemDto

    @Published
    private(set) var matches: [Element] = []

    private var searchQuery: CurrentValueSubject<String, Never> = .init("")

    // MARK: - Initialization

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        searchQuery
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self else { return }
                if query.isNotEmpty {
                    actuallySearch(query)
                } else {
                    matches = []
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @Function(\Action.Cases.search)
    private func _search(_ searchTerm: String) async throws {
        searchQuery.value = searchTerm

        await cancel()
    }

    @Function(\Action.Cases.actuallySearch)
    private func _actuallySearch(_ searchTerm: String) async throws {
        matches = try await searchElements(searchTerm)
    }

    @Function(\Action.Cases.add)
    private func _add(_ components: [Element]) async throws {
        try await addComponents(components)
        events.send(.updated)
    }

    @Function(\Action.Cases.remove)
    private func _remove(_ components: [Element]) async throws {
        try await removeComponents(components)
        events.send(.updated)
    }

    @Function(\Action.Cases.reorder)
    private func _reorder(_ components: [Element]) async throws {
        try await reorderComponents(components)
        events.send(.updated)
    }

    @Function(\Action.Cases.update)
    private func _update(_ newItem: BaseItemDto) async throws {
        try await updateItem(newItem)
        events.send(.updated)
    }

    // MARK: - Update Item

    func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        var updateItem = newItem
        updateItem.trickplay = nil

        let request = Paths.updateItem(itemID: itemId, updateItem)
        _ = try await userSession.client.send(request)

        item = try await item.getFullItem(userSession: userSession)

        Notifications[.itemMetadataDidChange].post(item)
    }

    // MARK: - Overridable Methods

    func searchElements(_ searchTerm: String) async throws -> [Element] {
        fatalError("Must be overridden in subclass")
    }

    func addComponents(_ components: [Element]) async throws {
        fatalError("Must be overridden in subclass")
    }

    func removeComponents(_ components: [Element]) async throws {
        fatalError("Must be overridden in subclass")
    }

    func reorderComponents(_ components: [Element]) async throws {
        fatalError("Must be overridden in subclass")
    }

    func containsElement(named name: String) -> Bool {
        fatalError("Must be overridden in subclass")
    }

    func matchExists(named name: String) -> Bool {
        fatalError("Must be overridden in subclass")
    }
}
