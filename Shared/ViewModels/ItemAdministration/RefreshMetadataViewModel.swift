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

@MainActor
@Stateful
final class RefreshMetadataViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refreshMetadata(
            metadataRefreshMode: MetadataRefreshMode,
            imageRefreshMode: MetadataRefreshMode,
            replaceMetadata: Bool,
            replaceImages: Bool,
            regenerateTrickplay: Bool
        )

        var transition: Transition {
            .loop(.refreshing)
        }
    }

    enum Event {
        case error
        case refreshing
    }

    enum State {
        case initial
        case refreshing
    }

    // MARK: - Published Items

    @Published
    private(set) var progress: Double = 0.0

    private var item: BaseItemDto

    // MARK: - Init

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    // MARK: - Metadata Refresh Logic

    @Function(\Action.Cases.refreshMetadata)
    private func _refreshMetadata(
        _ metadataRefreshMode: MetadataRefreshMode,
        _ imageRefreshMode: MetadataRefreshMode,
        _ replaceMetadata: Bool = false,
        _ replaceImages: Bool = false,
        _ regenerateTrickplay: Bool = false
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

        events.send(.refreshing)
        // TODO: Remove this call when we have a WebSocket
        try await self.refreshItem()
    }

    // MARK: - Refresh Item After Request Queued

    // TODO: Remove this func when we have a WebSocket
    private func refreshItem() async throws {
        try await pollRefreshProgress()

        // TODO: Call only this func via a Notification when we have a WebSocket
        // - We might be able to just get the full item/changes from the WebSocket
        let newItem = try await item.getFullItem(userSession: userSession)

        self.item = newItem
        self.progress = 0.0

        Notifications[.itemMetadataDidChange].post(newItem)
    }

    // MARK: - Poll Progress

    // TODO: Remove this func when we have a WebSocket
    private func pollRefreshProgress() async throws {
        let totalDuration: Double = 5.0
        let interval: Double = 0.05
        let steps = Int(totalDuration / interval)

        /// Update progress every 0.05 seconds. Ticks up "1%" at a time.
        for i in 1 ... steps {
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

            let currentProgress = Double(i) / Double(steps)
            self.progress = currentProgress
        }
    }
}
