//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging

/// Helper for performing shuffle actions on items
@MainActor
struct ShuffleActionHelper {

    private let logger = Logger.swiftfin()

    /// Initiates shuffle playback for the given item with the specified media source
    /// - Parameters:
    ///   - item: The item to shuffle (Series, Season, Collection, etc.)
    ///   - mediaSource: The media source to use for playback
    ///   - viewModel: The ItemViewModel for the item
    /// - Returns: A tuple containing the first item and the shuffle queue, or nil if shuffle is not supported
    func shuffleItem(
        _ item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        viewModel: ItemViewModel
    ) async throws -> (firstItem: BaseItemDto, queue: ShuffleMediaPlayerQueue)? {
        guard item.canShuffle else {
            logger.error("Shuffle not supported for item type: \(String(describing: item.type))")
            return nil
        }

        let shuffledItems: [BaseItemDto]

        // Get shuffled items based on item type
        if let seriesViewModel = viewModel as? SeriesItemViewModel {
            shuffledItems = try await seriesViewModel.getShuffledItems()
        } else if let collectionViewModel = viewModel as? CollectionItemViewModel {
            shuffledItems = try await collectionViewModel.getShuffledItems()
        } else {
            logger.error("No shuffle implementation for this ItemViewModel type")
            return nil
        }

        guard shuffledItems.isNotEmpty else {
            logger.error("No items to shuffle")
            return nil
        }

        guard var firstItem = shuffledItems.first else {
            logger.error("No first item in shuffled list")
            return nil
        }

        // Reset playback position for the first item
        firstItem.userData?.playbackPositionTicks = 0

        let queue = ShuffleMediaPlayerQueue(items: shuffledItems)

        return (firstItem, queue)
    }

    /// Initiates shuffle playback and routes to the video player (tvOS/fixed media source)
    /// - Parameters:
    ///   - item: The item to shuffle
    ///   - mediaSource: The media source to use for playback
    ///   - viewModel: The ItemViewModel for the item
    ///   - router: The router to use for navigation
    func shuffleAndPlay(
        _ item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        viewModel: ItemViewModel,
        router: NavigationCoordinator.Router
    ) async throws {
        guard let result = try await shuffleItem(item, mediaSource: mediaSource, viewModel: viewModel) else {
            return
        }

        let manager = MediaPlayerManager(
            item: result.firstItem,
            queue: result.queue
        ) { item in
            try await MediaPlayerItem.build(for: item, mediaSource: mediaSource)
        }

        await MainActor.run {
            router.route(to: .videoPlayer(manager: manager))
        }
    }

    /// Initiates shuffle playback and routes to the video player (iOS/auto-select media source)
    /// - Parameters:
    ///   - item: The item to shuffle
    ///   - viewModel: The ItemViewModel for the item
    ///   - router: The router to use for navigation
    func shuffleAndPlayWithAutoSource(
        _ item: BaseItemDto,
        viewModel: ItemViewModel,
        router: NavigationCoordinator.Router
    ) async throws {
        guard let result = try await shuffleItem(item, mediaSource: MediaSourceInfo(), viewModel: viewModel) else {
            return
        }

        // iOS: Let each item auto-select its media source
        let provider = MediaPlayerItemProvider(item: result.firstItem) { item in
            try await MediaPlayerItem.build(for: item) {
                $0.userData?.playbackPositionTicks = 0
            }
        }

        await MainActor.run {
            router.route(
                to: .videoPlayer(
                    provider: provider,
                    queue: result.queue
                )
            )
        }
    }

    // MARK: - Library Shuffle Utilities

    /// Collects playable items from a mixed collection, expanding containers into their playable content.
    ///
    /// Containers (series, boxSets) cannot be played directly and are expanded into their playable content.
    /// BoxSets may contain series, which are recursively expanded into episodes.
    /// Other items (movies, episodes, etc.) are included as-is if playable and have media sources.
    ///
    /// - Parameter items: The items to process (may include series, collections, movies, episodes, etc.)
    /// - Returns: A flat list of playable items with containers expanded into their playable content
    static func collectPlayableItems(from items: [BaseItemDto]) async throws -> [BaseItemDto] {
        guard let userSession = Container.shared.currentUserSession() else {
            throw JellyfinAPIError("No user session")
        }

        var playableItems: [BaseItemDto] = []

        for item in items {
            switch item.type {
            case .series:
                // Series are containers - fetch and include all their episodes
                let episodes = try await fetchEpisodes(for: item, userSession: userSession)
                playableItems.append(contentsOf: episodes)
            case .boxSet:
                // BoxSets are containers - fetch contents and recursively expand any series
                let contents = try await fetchBoxSetContents(for: item, userSession: userSession)
                let expandedContents = try await collectPlayableItems(from: contents)
                playableItems.append(contentsOf: expandedContents)
            default:
                // Include directly playable items (movies, episodes, etc.) that have media sources
                if item.isPlayable && item.mediaSources?.isNotEmpty == true {
                    playableItems.append(item)
                }
            }
        }

        return playableItems
    }

    /// Fetches all episodes for a given series
    /// - Parameters:
    ///   - series: The series to fetch episodes for
    ///   - userSession: The current user session
    /// - Returns: Array of episodes with media sources
    private static func fetchEpisodes(for series: BaseItemDto, userSession: UserSession) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.episode]
        parameters.isRecursive = true
        parameters.parentID = series.id
        parameters.sortBy = [ItemSortBy.sortName.rawValue]
        parameters.sortOrder = [.ascending]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)
        let episodes = response.value.items ?? []

        return episodes.filter { $0.mediaSources?.isNotEmpty ?? false }
    }

    /// Fetches all contents for a given boxSet/collection
    /// - Parameters:
    ///   - boxSet: The boxSet to fetch contents for
    ///   - userSession: The current user session
    /// - Returns: Array of items in the collection (may include series, movies, etc.)
    private static func fetchBoxSetContents(for boxSet: BaseItemDto, userSession: UserSession) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.isRecursive = true
        parameters.parentID = boxSet.id
        parameters.sortBy = [ItemSortBy.sortName.rawValue]
        parameters.sortOrder = [.ascending]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
