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

        /// Generic Actions
        case delete
        case refreshItem(sendNotification: Bool)
        case refreshMetadata(
            metadataRefreshMode: MetadataRefreshMode,
            imageRefreshMode: MetadataRefreshMode,
            replaceMetadata: Bool,
            replaceImages: Bool,
            regenerateTrickplay: Bool
        )

        /// Component Actions
        case search(String)
        case actuallySearch(String)
        case add([Element])
        case remove([Element])
        case reorder([Element])
        case update(BaseItemDto)

        var transition: Transition {
            switch self {
            case .add, .delete, .remove, .reorder, .update, .refreshItem, .refreshMetadata:
                .background(.updating)
            case .search:
                .to(.initial)
            case .actuallySearch:
                .background(.searching)
            }
        }
    }

    enum BackgroundState {
        case updating
        case searching
    }

    enum Event {
        case deleted
        case metadataRefreshStarted
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

    @Function(\Action.Cases.delete)
    private func _delete() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.deleteItem(itemID: itemID)
        _ = try await userSession.client.send(request)

        Notifications[.didDeleteItem].post(itemID)
        events.send(.deleted)
    }

    @Function(\Action.Cases.refreshMetadata)
    private func _refreshMetadata(
        _ metadataRefreshMode: MetadataRefreshMode,
        _ imageRefreshMode: MetadataRefreshMode,
        _ replaceMetadata: Bool,
        _ replaceImages: Bool,
        _ regenerateTrickplay: Bool
    ) async throws {
        guard let itemId = item.id else { return }

        var parameters = Paths.RefreshItemParameters()
        parameters.metadataRefreshMode = metadataRefreshMode
        parameters.imageRefreshMode = imageRefreshMode
        parameters.isReplaceAllMetadata = replaceMetadata
        parameters.isReplaceAllImages = replaceImages
        parameters.isRegenerateTrickplay = regenerateTrickplay

        let request = Paths.refreshItem(
            itemID: itemId,
            parameters: parameters
        )
        _ = try await userSession.client.send(request)

        events.send(.metadataRefreshStarted)

        // TODO: Remove this call when we have a WebSocket
        // - Both lines below this can be replaced by the WebSocket
        // - Centralized, WebSocket gets the new information and updates when new
        // - Currently, waits 5 seconds before a manual refresh
        try await Task.sleep(for: .seconds(5))
        await refreshItem(sendNotification: true)
    }

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
    }

    @Function(\Action.Cases.remove)
    private func _remove(_ components: [Element]) async throws {
        try await removeComponents(components)
    }

    @Function(\Action.Cases.reorder)
    private func _reorder(_ components: [Element]) async throws {
        try await reorderComponents(components)
    }

    @Function(\Action.Cases.update)
    private func _update(_ newItem: BaseItemDto) async throws {
        try await updateItem(newItem)
    }

    @Function(\Action.Cases.refreshItem)
    private func _refreshItem(_ isRefresh: Bool) async throws {
        item = try await item.getFullItem(userSession: userSession, isRefresh: isRefresh)
        events.send(.updated)
    }

    // MARK: - Update Item

    func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        var updateItem = newItem
        updateItem.trickplay = nil

        let request = Paths.updateItem(itemID: itemId, updateItem)
        _ = try await userSession.client.send(request)

        await refreshItem(sendNotification: true)
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
