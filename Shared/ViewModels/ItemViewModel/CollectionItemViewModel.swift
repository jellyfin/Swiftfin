//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

final class CollectionItemViewModel: ItemViewModel {

    // MARK: - Published Collection Items

    @Published
    private(set) var collectionItems: OrderedDictionary<BaseItemKind, [BaseItemDto]> = [:]

    // MARK: - On Refresh

    override func onRefresh() async throws {
        let collectionItems = try await self.getCollectionItems()
        let playButtonItem = try await self.getPlayButtonItem(collectionItems)

        await MainActor.run {
            self.collectionItems = collectionItems
            self.playButtonItem = playButtonItem
        }
    }

    // MARK: - Get Collection Items

    private func getCollectionItems() async throws -> OrderedDictionary<BaseItemKind, [BaseItemDto]> {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.parentID = item.id

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        let items = response.value.items ?? []

        let groupedItems: OrderedDictionary<BaseItemKind?, [BaseItemDto]> = .init(
            grouping: items,
            by: \.type
        )

        return groupedItems
            .compactKeys()
    }

    // MARK: - Get Play Button Items

    private func getPlayButtonItem(_ items: OrderedDictionary<BaseItemKind, [BaseItemDto]>) async throws -> BaseItemDto? {
        let allItems = items.values.flatMap { $0 }
        let selectedItem: BaseItemDto

        /// Determine the item that we need to get the PlayButtonItem
        if let firstUnplayed = allItems.first(where: { $0.userData?.isPlayed == false && $0.type != .boxSet }) {
            selectedItem = firstUnplayed
        } else if let firstItem = allItems.first {
            selectedItem = firstItem
        } else {
            return nil
        }

        switch selectedItem.type {
        case .episode, .movie:
            return selectedItem
        case .season:
            return try await getFirstItem(season: selectedItem)
        case .series:
            return try await getFirstItem(series: selectedItem)
        default:
            return nil
        }
    }

    // MARK: - Get First Item from Series

    private func getFirstItem(series: BaseItemDto) async throws -> BaseItemDto? {
        guard let seriesID = series.id else {
            return nil
        }

        let request = Paths.getSeasons(seriesID: seriesID)
        let response = try await userSession.client.send(request)

        if let unplayedSeason = response.value.items?.first(where: { $0.userData?.isPlayed == false }) {
            return try await getFirstItem(season: unplayedSeason)
        } else if let firstSeason = response.value.items?.first {
            return try await getFirstItem(season: firstSeason)
        } else {
            return nil
        }
    }

    // MARK: - Get First Item from Season

    private func getFirstItem(season: BaseItemDto) async throws -> BaseItemDto? {
        guard let seasonID = season.id, let seriesID = season.seriesID else {
            return nil
        }

        var parameters = Paths.GetEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isMissing = false
        parameters.seasonID = seasonID
        parameters.userID = userSession.user.id

        let request = Paths.getEpisodes(
            seriesID: seriesID,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        if let unplayedEpisode = response.value.items?.first(where: { $0.userData?.isPlayed == false }) {
            return unplayedEpisode
        } else if let firstEpisode = response.value.items?.first {
            return firstEpisode
        } else {
            return nil
        }
    }
}
