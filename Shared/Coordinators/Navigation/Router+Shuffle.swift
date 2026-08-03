//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging
import SwiftUI

extension Router.Wrapper {

    /// Guards against concurrent launches across all entry points; a view-local
    /// flag can't, as context menus destroy their `@State` on dismiss.
    @MainActor
    private static var isShuffling = false

    /// Routes into the video player playing the container's children in a
    /// server-randomized order, optionally matching the given filters.
    @MainActor
    func shuffle(
        item: BaseItemDto,
        filters: ItemFilterCollection? = nil,
        isShuffling: Binding<Bool> = .constant(false)
    ) {
        guard !Self.isShuffling else { return }
        Self.isShuffling = true
        isShuffling.wrappedValue = true

        Task {
            defer {
                Self.isShuffling = false
                isShuffling.wrappedValue = false
            }

            let logger = Logger.swiftfin()

            do {
                guard let (firstItem, queue) = try await ShuffleMediaPlayerQueue.build(for: item, filters: filters) else {
                    logger.error("No items to shuffle for \(item.displayTitle)")
                    return
                }

                route(
                    to: .videoPlayer(
                        provider: queue.makeProvider(for: firstItem),
                        queue: queue
                    )
                )
            } catch {
                logger.error("Error shuffling item: \(error.localizedDescription)")
            }
        }
    }
}
