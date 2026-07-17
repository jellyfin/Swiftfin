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
class ItemEditorViewModel: ViewModel {

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
        case update(BaseItemDto)

        var transition: Transition {
            switch self {
            case .delete, .update, .refreshItem, .refreshMetadata:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
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

    // MARK: - Initialization

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Actions

    @Function(\Action.Cases.delete)
    private func _delete() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.deleteItem(itemID: itemID)
        _ = try await send(request)

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
        _ = try await send(request)

        events.send(.metadataRefreshStarted)

        // TODO: Remove this call when we have a WebSocket
        // - Both lines below this can be replaced by the WebSocket
        // - Centralized, WebSocket gets the new information and updates when new
        // - Currently, waits 5 seconds before a manual refresh
        try await Task.sleep(for: .seconds(5))
        await refreshItem(sendNotification: true)
    }

    @Function(\Action.Cases.update)
    private func _update(_ newItem: BaseItemDto) async throws {
        try await updateItem(newItem)
    }

    @Function(\Action.Cases.refreshItem)
    private func _refreshItem(_ isRefresh: Bool) async throws {
        self.item = try await item.getFullItem(userSession: requireUserSession(), sendNotification: isRefresh)
        events.send(.updated)
    }

    // MARK: - Update Item

    // TODO: call update(_:) instead

    func updateItem(_ newItem: BaseItemDto) async throws {
        guard let itemId = item.id else { return }

        var updateItem = newItem
        updateItem.trickplay = nil

        let request = Paths.updateItem(itemID: itemId, updateItem)
        _ = try await send(request)

        await refreshItem(sendNotification: true)
    }
}
