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
import SwiftUI

@MainActor
struct ShuffleActionHelper {

    private let logger = Logger.swiftfin()

    final class FetchState {
        var excludeItemIDs: Set<String>
        var excludeLibraryItemIDs: Set<String>?

        init(excludeItemIDs: Set<String>, excludeLibraryItemIDs: Set<String>? = nil) {
            self.excludeItemIDs = excludeItemIDs
            self.excludeLibraryItemIDs = excludeLibraryItemIDs
        }
    }

    func shuffleItem(
        _ item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        viewModel: ItemViewModel
    ) async throws -> (firstItem: BaseItemDto, queue: ShuffleMediaPlayerQueue)? {
        guard item.canShuffle else {
            logger.error("Shuffle not supported for item type: \(String(describing: item.type))")
            return nil
        }

        let shuffledItems = try await viewModel.getShuffledItems()

        guard shuffledItems.isNotEmpty else {
            logger.error("No items to shuffle")
            return nil
        }

        guard var firstItem = shuffledItems.first else {
            logger.error("No first item in shuffled list")
            return nil
        }

        firstItem.userData?.playbackPositionTicks = 0

        let fetchState = FetchState(excludeItemIDs: Set(shuffledItems.compactMap(\.id)))
        let fetchMoreItems: () async throws -> [BaseItemDto] = { [weak viewModel, fetchState] in
            guard let viewModel else { return [] }
            let newItems = try await viewModel.getShuffledItems(excluding: Array(fetchState.excludeItemIDs))
            fetchState.excludeItemIDs.formUnion(newItems.compactMap(\.id))
            return newItems
        }

        let queue = ShuffleMediaPlayerQueue(items: shuffledItems, fetchMoreItems: fetchMoreItems)

        return (firstItem, queue)
    }

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

    func shuffleAndPlay(
        _ item: BaseItemDto,
        viewModel: ItemViewModel,
        router: NavigationCoordinator.Router,
        autoSelectMediaSource: Bool = false
    ) async throws {
        if autoSelectMediaSource {
            guard let result = try await shuffleItem(item, mediaSource: MediaSourceInfo(), viewModel: viewModel) else {
                return
            }

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
        } else {
            let containerTypes: Set<BaseItemKind> = [.series, .boxSet, .collectionFolder, .folder, .playlist]

            let mediaSource: MediaSourceInfo
            if let itemType = item.type, containerTypes.contains(itemType) {
                mediaSource = MediaSourceInfo()
            } else {
                guard let selectedMediaSource = viewModel.selectedMediaSource else {
                    logger.error("Shuffle selected with no media source for playable item")
                    return
                }
                mediaSource = selectedMediaSource
            }

            try await shuffleAndPlay(
                item,
                mediaSource: mediaSource,
                viewModel: viewModel,
                router: router
            )
        }
    }

    static func collectPlayableItems(from items: [BaseItemDto]) async throws -> [BaseItemDto] {
        guard let userSession = Container.shared.currentUserSession() else {
            throw JellyfinAPIError("No user session")
        }

        var playableItems: [BaseItemDto] = []

        for item in items {
            if item.type == .series || item.type == .boxSet || item.type == .collectionFolder || item.type == .folder {
                let contents = try await fetchVideoItemsPaginated(for: item, userSession: userSession)
                playableItems.append(contentsOf: contents)
            } else if item.isPlayable && item.mediaSources?.isNotEmpty == true {
                playableItems.append(item)
            }
        }

        // .shuffled() needed to break up grouping from sequential container expansion
        return playableItems.shuffled()
    }

    private static func fetchVideoItemsPaginated(
        for parent: BaseItemDto,
        userSession: UserSession
    ) async throws -> [BaseItemDto] {
        let pageSize = ShuffleQueueConstants.pageSize
        let maxItems = ShuffleQueueConstants.targetQueueSize
        var allItems: [BaseItemDto] = []
        var startIndex = 0
        var excludeItemIDs: [String] = []

        while allItems.count < maxItems {
            var parameters = Paths.GetItemsByUserIDParameters()
            parameters.fields = .MinimumFields
            parameters.isRecursive = true
            parameters.parentID = parent.id
            parameters.sortBy = [ItemSortBy.random.rawValue]
            parameters.includeItemTypes = [.episode, .movie, .video, .musicVideo, .trailer]
            parameters.limit = min(pageSize, maxItems - allItems.count)
            parameters.startIndex = startIndex

            if excludeItemIDs.isNotEmpty {
                parameters.excludeItemIDs = excludeItemIDs
            }

            let request = Paths.getItemsByUserID(
                userID: userSession.user.id,
                parameters: parameters
            )
            let response = try await userSession.client.send(request)

            let pageItems = (response.value.items ?? [])
                .filter { $0.isPlayable && $0.mediaSources?.isNotEmpty == true }

            allItems.append(contentsOf: pageItems)
            excludeItemIDs.append(contentsOf: pageItems.compactMap(\.id))

            if pageItems.count < pageSize || allItems.count >= maxItems {
                break
            }

            startIndex += pageSize
        }

        return allItems
    }

    static func createLibraryShuffleManager<Element: Poster>(
        firstItem: BaseItemDto,
        playableItems: [BaseItemDto],
        originalLibraryItems: [BaseItemDto],
        viewModel: ItemLibraryViewModel,
        backgroundStates: inout Set<PagingLibraryViewModel<Element>.BackgroundState>
    ) -> MediaPlayerManager {
        var mutableFirstItem = firstItem
        mutableFirstItem.userData?.playbackPositionTicks = 0

        let excludeItemIDs = Set(playableItems.compactMap(\.id))
        let excludeLibraryItemIDs = Set(originalLibraryItems.compactMap(\.id))

        let fetchState = FetchState(excludeItemIDs: excludeItemIDs, excludeLibraryItemIDs: excludeLibraryItemIDs)
        let fetchMoreItems: () async throws -> [BaseItemDto] = { [weak viewModel, fetchState] in
            guard let viewModel = viewModel as? ItemLibraryViewModel else { return [] }
            guard let excludeLibraryItemIDs = fetchState.excludeLibraryItemIDs else { return [] }
            let excludeArray = Array(excludeLibraryItemIDs)
            let newLibraryItems = try await viewModel.getShuffledItems(excluding: excludeArray)
            guard !newLibraryItems.isEmpty else { return [] }

            fetchState.excludeLibraryItemIDs?.formUnion(newLibraryItems.compactMap(\.id))

            let playableItems = try await Self.collectPlayableItems(from: newLibraryItems)

            let uniquePlayableItems = playableItems.filter { item in
                guard let id = item.id else { return false }
                return !fetchState.excludeItemIDs.contains(id)
            }

            fetchState.excludeItemIDs.formUnion(uniquePlayableItems.compactMap(\.id))

            return uniquePlayableItems
        }

        let queue = ShuffleMediaPlayerQueue(items: playableItems, fetchMoreItems: fetchMoreItems)
        let manager = MediaPlayerManager(
            item: mutableFirstItem,
            queue: queue
        ) { item in
            try await MediaPlayerItem.build(for: item) {
                $0.userData?.playbackPositionTicks = 0
            }
        }

        manager.$state
            .sink { [weak viewModel] state in
                if state == .playback {
                    viewModel?.backgroundStates.remove(.shuffling)
                }
            }
            .store(in: &manager.cancellables)

        manager.$playbackItem
            .sink { [weak viewModel] playbackItem in
                if playbackItem != nil {
                    viewModel?.backgroundStates.remove(.shuffling)
                }
            }
            .store(in: &manager.cancellables)

        return manager
    }

    func playLibraryShuffle<Element: Poster>(
        items: [BaseItemDto],
        viewModel: PagingLibraryViewModel<Element>,
        router: NavigationCoordinator.Router,
        namespace: Namespace.ID? = nil
    ) async {
        do {
            let originalLibraryItems = items
            let playableItems = try await Self.collectPlayableItems(from: items)

            guard let firstItem = playableItems.first else {
                logger.warning("No playable items found after expanding containers")
                return
            }

            guard let libraryViewModel = viewModel as? ItemLibraryViewModel else { return }

            let manager = Self.createLibraryShuffleManager(
                firstItem: firstItem,
                playableItems: playableItems,
                originalLibraryItems: originalLibraryItems,
                viewModel: libraryViewModel,
                backgroundStates: &viewModel.backgroundStates
            )

            await MainActor.run {
                router.route(
                    to: .videoPlayer(manager: manager),
                    in: namespace
                )
            }
        } catch {
            logger.error("Error playing shuffled items: \(error)")
        }
    }
}
