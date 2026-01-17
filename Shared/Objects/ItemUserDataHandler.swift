//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

extension Container {

    var itemUserDataHandler: Factory<ItemUserDataHandler> {
        self { ItemUserDataHandler() }
            .singleton
    }
}

@MainActor
class ItemUserDataHandler: ViewModel {

    private var favoriteItemTasks: [String: Task<Void, Never>] = [:]
    private var playedItemTasks: [String: Task<Void, Never>] = [:]
    private var progressTasks: [String: Task<Void, Never>] = [:]

    func setFavoriteStatus(
        for item: BaseItemDto,
        isFavorited: Bool
    ) {
        guard let itemID = item.id else { return }

        favoriteItemTasks[itemID]?.cancel()

        let task = Task {
            do {

                let newUserData: UserItemDataDto

                if isFavorited {
                    newUserData = try await userSession.client.send(
                        Paths.markFavoriteItem(itemID: itemID)
                    ).value
                } else {
                    newUserData = try await userSession.client.send(
                        Paths.unmarkFavoriteItem(itemID: itemID)
                    ).value
                }

                Notifications[.itemUserDataDidChange].post(newUserData)
            } catch {
                print("Failed to update favorite status for item \(itemID): \(error)")
            }

            favoriteItemTasks[itemID] = nil
        }

        favoriteItemTasks[itemID] = task
    }

    func setPlaybackProgress(
        for item: BaseItemDto,
        progress: Duration
    ) {
        guard var newUserData = item.userData else { return }
        newUserData.playbackPosition = progress

        Notifications[.itemUserDataDidChange].post(newUserData)
    }

    func setPlayedStatus(
        for item: BaseItemDto,
        isPlayed: Bool
    ) {
        guard let itemID = item.id else { return }

        playedItemTasks[itemID]?.cancel()

        let task = Task {
            do {
                let newUserData: UserItemDataDto

                if isPlayed {
                    newUserData = try await userSession.client.send(
                        Paths.markPlayedItem(itemID: itemID)
                    ).value
                } else {
                    newUserData = try await userSession.client.send(
                        Paths.markUnplayedItem(itemID: itemID)
                    ).value
                }

                Notifications[.itemUserDataDidChange].post(newUserData)
            } catch {
                print("Failed to update played status for item \(itemID): \(error)")
            }
        }

        playedItemTasks[itemID] = task
    }
}
