//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import Combine
import Defaults
import Foundation
import JellyfinAPI
import Logging
import SwiftUI

@MainActor
class ShuffleMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager? {
        didSet {
            cancellables = []
            guard let manager else { return }
            manager.$playbackItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newItem in
                    Task { @MainActor [weak self] in
                        self?.didReceive(newItem: newItem)
                    }
                }
                .store(in: &cancellables)
        }
    }

    let displayTitle: String = L10n.episodes
    let id: String = "ShuffleMediaPlayerQueue"

    @Published
    var nextItem: MediaPlayerItemProvider? = nil
    @Published
    var previousItem: MediaPlayerItemProvider? = nil

    @Published
    var hasNextItem: Bool = false
    @Published
    var hasPreviousItem: Bool = false

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    private var shuffledItems: [BaseItemDto] = []
    private var currentIndex: Int = 0
    private var fetchMoreItems: (() async throws -> [BaseItemDto])?
    private var excludeItemIDs: Set<String> = []
    private var isFetchingMore = false

    init(items: [BaseItemDto], fetchMoreItems: (() async throws -> [BaseItemDto])? = nil) {
        self.shuffledItems = items
        self.fetchMoreItems = fetchMoreItems
        self.excludeItemIDs = Set(items.compactMap(\.id))
        super.init()
        updateAdjacentItems()
    }

    var videoPlayerBody: some PlatformView {
        ShuffleQueueOverlay(items: shuffledItems, currentIndex: currentIndex)
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        guard let newItem else {
            updateAdjacentItems()
            return
        }

        if let index = shuffledItems.firstIndex(where: { $0.id == newItem.baseItem.id }) {
            currentIndex = index
        }

        updateAdjacentItems()
    }

    private func updateAdjacentItems() {
        let hasPrevious = currentIndex > 0
        let remainingItems = shuffledItems.count - currentIndex - 1
        let hasNext = remainingItems > 0

        logger
            .info(
                "Updating adjacent items: current index = \(currentIndex), hasNext = \(hasNext), hasPrevious = \(hasPrevious), remaining = \(remainingItems)"
            )

        if remainingItems <= ShuffleQueueConstants.fetchThreshold, let fetchMore = fetchMoreItems, !isFetchingMore {
            Task { @MainActor [weak self] in
                await self?.fetchMoreItemsIfNeeded()
            }
        }

        var nextProvider: MediaPlayerItemProvider?
        var previousProvider: MediaPlayerItemProvider?

        if hasNext {
            let nextItem = shuffledItems[currentIndex + 1]
            logger.info("Next item: \(nextItem.displayTitle)")
            nextProvider = MediaPlayerItemProvider(item: nextItem) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        } else {
            logger.info("No next item available")
        }

        if hasPrevious {
            let previousItem = shuffledItems[currentIndex - 1]
            logger.info("Previous item: \(previousItem.displayTitle)")
            previousProvider = MediaPlayerItemProvider(item: previousItem) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        }

        self.nextItem = nextProvider
        self.previousItem = previousProvider
        self.hasNextItem = hasNext
        self.hasPreviousItem = hasPrevious

        logger
            .info(
                "Updated: nextItem = \(nextProvider?.item.displayTitle ?? "nil"), previousItem = \(previousProvider?.item.displayTitle ?? "nil")"
            )
    }

    private func fetchMoreItemsIfNeeded() async {
        guard let fetchMore = fetchMoreItems, !isFetchingMore else { return }

        let remainingItems = shuffledItems.count - currentIndex - 1
        guard remainingItems <= ShuffleQueueConstants.fetchThreshold else { return }

        isFetchingMore = true
        defer { isFetchingMore = false }

        do {
            let newItems = try await fetchMore()

            let uniqueNewItems = newItems.filter { item in
                guard let id = item.id else { return false }
                return !excludeItemIDs.contains(id)
            }

            guard !uniqueNewItems.isEmpty else {
                logger.info("No new unique items to add (all were duplicates)")
                return
            }

            shuffledItems.append(contentsOf: uniqueNewItems)
            excludeItemIDs.formUnion(uniqueNewItems.compactMap(\.id))

            logger.info("Fetched \(uniqueNewItems.count) more items, queue size now: \(shuffledItems.count)")

            updateAdjacentItems()
        } catch {
            logger.error("Error fetching more items: \(error)")
        }
    }
}

extension ShuffleMediaPlayerQueue {

    private struct ShuffleQueueOverlay: PlatformView {

        let items: [BaseItemDto]
        let currentIndex: Int

        var iOSView: some View {
            CompactOrRegularShuffleView(items: items, currentIndex: currentIndex)
        }

        var tvOSView: some View {
            EmptyView()
        }
    }

    private struct CompactOrRegularShuffleView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        let items: [BaseItemDto]
        let currentIndex: Int

        var body: some View {
            CompactOrRegularView(isCompact: containerState.isCompact) {
                CompactShuffleView(items: items, currentIndex: currentIndex)
            } regularView: {
                RegularShuffleView(items: items, currentIndex: currentIndex)
            }
        }
    }

    private struct CompactShuffleView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let items: [BaseItemDto]
        let currentIndex: Int

        private func selectItem(_ item: BaseItemDto) {
            let provider = MediaPlayerItemProvider(item: item) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }

            manager.playNewItem(provider: provider)
            containerState.select(supplement: nil)
        }

        var body: some View {
            CollectionVGrid(
                uniqueElements: items,
                id: \.unwrappedIDHashOrZero,
                layout: .columns(
                    1,
                    insets: .init(top: 0, leading: 0, bottom: EdgeInsets.edgePadding, trailing: 0)
                )
            ) { item in
                MediaPlayerQueueItemViews.ItemRow(item: item) {
                    selectItem(item)
                }
                .edgePadding(.horizontal)
            }
        }
    }

    private struct RegularShuffleView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        let items: [BaseItemDto]
        let currentIndex: Int

        private func selectItem(_ item: BaseItemDto) {
            let provider = MediaPlayerItemProvider(item: item) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }

            manager.playNewItem(provider: provider)
            containerState.select(supplement: nil)
        }

        var body: some View {
            MediaPlayerQueueItemViews.QueueHStack(
                items: items,
                action: selectItem
            )
        }
    }
}

// MARK: - Constants

enum ShuffleQueueConstants {

    /// Target number of items to maintain in the shuffle queue
    static let targetQueueSize = 20

    /// Number of items remaining before fetching more (half of target size)
    static var fetchThreshold: Int {
        targetQueueSize / 2
    }

    /// Page size for fetching items from the API
    static let pageSize = 20
}
