//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import Combine
import Defaults
import FactoryKit
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
class ShuffleMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager? {
        didSet {
            playbackItemObserver = nil
            guard let manager else { return }
            playbackItemObserver = manager.$playbackItem
                .sink { [weak self] newItem in
                    self?.didReceive(newItem: newItem)
                }
        }
    }

    let displayTitle: String = L10n.shuffle
    let id: String = "ShuffleMediaPlayerQueue"

    @Published
    var nextItem: MediaPlayerItemProvider? = nil
    @Published
    var previousItem: MediaPlayerItemProvider? = nil

    @Published
    var hasNextItem: Bool = false
    @Published
    var hasPreviousItem: Bool = false

    @Published
    private var elements: [BaseItemDto]

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    private var currentIndex: Int = 0
    private var playbackItemObserver: AnyCancellable?

    /// The playable item types a container can shuffle across.
    private static let itemTypes: [BaseItemKind] = [.episode, .movie, .video, .musicVideo, .trailer]

    /// Items fetched per request while filling the queue.
    private static let pageSize = 20

    /// Upper bound on the shuffled queue's size. The server has no stable random
    /// seed, so instead of paging (which re-randomizes every request) the queue is
    /// filled once up to this cap using `excludeItemIDs` to avoid duplicates.
    private static let targetQueueSize = 100

    /// Fetches a capped, de-duplicated set of random children for a parent and returns
    /// the initial item to play alongside a queue seeded with the full set.
    ///
    /// The parent's playable descendants are sorted randomly by the server rather than
    /// shuffled locally.
    static func build(for parent: BaseItemDto) async throws -> (firstItem: BaseItemDto, queue: ShuffleMediaPlayerQueue)? {
        guard let userSession = Container.shared.currentUserSession() else {
            throw ErrorMessage(L10n.unknownError)
        }

        let items = try await fetchShuffledItems(parentID: parent.id, userSession: userSession)

        guard let firstItem = items.first else { return nil }

        let queue = ShuffleMediaPlayerQueue(elements: items)
        return (firstItem, queue)
    }

    private init(elements: [BaseItemDto]) {
        self.elements = elements
        super.init()

        updateAdjacentItems()
    }

    var videoPlayerBody: some PlatformView {
        ShuffleOverlay(queue: self)
    }

    /// Repeatedly requests random items, excluding those already collected, until the
    /// server runs out of new items or the queue cap is reached. Excluding collected IDs
    /// is what keeps the set duplicate-free despite the server re-randomizing each request.
    private static func fetchShuffledItems(
        parentID: String?,
        userSession: UserSession
    ) async throws -> [BaseItemDto] {
        var items: [BaseItemDto] = []
        var excludeIDs: [String] = []

        while items.count < targetQueueSize {
            var parameters = Paths.GetItemsParameters()
            parameters.enableUserData = true
            parameters.fields = .MinimumFields
            parameters.isRecursive = true
            parameters.parentID = parentID
            parameters.includeItemTypes = itemTypes
            parameters.sortBy = [.random]
            let requestedLimit = min(pageSize, targetQueueSize - items.count)
            parameters.limit = requestedLimit
            parameters.userID = userSession.user.id

            if excludeIDs.isNotEmpty {
                parameters.excludeItemIDs = excludeIDs
            }

            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            let returned = response.value.items ?? []
            let page = returned.filter(\.isPlayable)

            items.append(contentsOf: page)
            excludeIDs.append(contentsOf: returned.compactMap(\.id))

            // fewer than requested means the server is exhausted
            if returned.count < requestedLimit {
                break
            }
        }

        return items
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        // clear neighbors when the item isn't in the shuffled set
        guard let newItem, let index = elements.firstIndex(where: { $0.id == newItem.baseItem.id }) else {
            nextItem = nil
            previousItem = nil
            hasNextItem = false
            hasPreviousItem = false
            return
        }

        currentIndex = index
        updateAdjacentItems()
    }

    private func updateAdjacentItems() {
        let previous = currentIndex > 0 ? elements[currentIndex - 1] : nil
        let next = currentIndex + 1 < elements.count ? elements[currentIndex + 1] : nil

        nextItem = next.map { makeProvider(for: $0) }
        previousItem = previous.map { makeProvider(for: $0) }
        hasNextItem = next != nil
        hasPreviousItem = previous != nil
    }

    private func makeProvider(for item: BaseItemDto) -> MediaPlayerItemProvider {
        MediaPlayerItemProvider(item: item) { [weak self] item in
            let bitrate = await self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]
            return try await MediaPlayerItem.build(for: item, requestedBitrate: bitrate) {
                $0.userData?.playbackPositionTicks = .zero
            }
        }
    }

    fileprivate var displayedElements: [BaseItemDto] {
        elements
    }
}

extension ShuffleMediaPlayerQueue {

    private struct ShuffleOverlay: PlatformView {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var queue: ShuffleMediaPlayerQueue

        private func select(item: BaseItemDto) {
            let provider = MediaPlayerItemProvider(item: item) { [manager] item in
                try await MediaPlayerItem.build(for: item, requestedBitrate: manager.playbackBitrate) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }

            manager.playNewItem(provider: provider)
        }

        var iOSView: some View {
            CompactOrRegularView(isCompact: containerState.isCompact) {
                CompactView(items: queue.displayedElements, action: select)
            } regularView: {
                RegularView(items: queue.displayedElements, action: select)
            }
        }

        var tvOSView: some View {
            TVOSView(items: queue.displayedElements, action: select)
        }
    }

    private struct TVOSView: View {

        let items: [BaseItemDto]
        let action: (BaseItemDto) -> Void

        var body: some View {
            CollectionHStack(
                uniqueElements: items,
                id: \.id,
                layout: .grid(columns: 5, rows: 1, columnTrailingInset: 0)
            ) { item in
                ItemButton(item: item) {
                    action(item)
                }
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .focusSection()
        }
    }

    private struct CompactView: View {

        let items: [BaseItemDto]
        let action: (BaseItemDto) -> Void

        var body: some View {
            CollectionVGrid(
                uniqueElements: items,
                id: \.id,
                layout: .columns(1, insets: .edgeInsets)
            ) { item in
                ItemRow(item: item) {
                    action(item)
                }
            }
        }
    }

    private struct RegularView: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        let items: [BaseItemDto]
        let action: (BaseItemDto) -> Void

        var body: some View {
            CollectionHStack(
                uniqueElements: items,
                id: \.id,
                layout: .minimumWidth(columnWidth: 170, rows: 1)
            ) { item in
                ItemButton(item: item) {
                    action(item)
                }
            }
            .clipsToBounds(false)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollBehavior(.continuousLeadingEdge)
        }
    }

    private struct ItemPreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        let item: BaseItemDto

        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.complexSecondary)

                ImageView(item.imageSource(.primary, environment: ImageSourceOptions(maxWidth: 200)))
                    .failure {
                        SystemImageContentView(systemName: item.systemImage)
                    }
            }
            .overlay {
                if isSelected {
                    ContainerRelativeShape()
                        .stroke(accentColor, lineWidth: 8)
                        .clipped()
                }
            }
            .posterStyle(.landscape)
        }
    }

    private struct ItemDescription: View {

        let item: BaseItemDto

        var body: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLabel = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLabel)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private struct ItemRow: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto
        let action: () -> Void

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                ItemPreview(item: item)
                    .frame(width: 110)
                    .padding(.vertical, 8)
            } content: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    ItemDescription(item: item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } action: {
                action()
            }
            .isSelected(manager.item.id == item.id)
        }
    }

    private struct ItemButton: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto
        let action: () -> Void

        var body: some View {
            PosterButton(
                item: item._withLandscapeImages { environment in
                    [item.imageSource(.primary, environment: environment)]
                },
                displayType: .landscape
            ) { _ in
                action()
            }
            .isSelected(manager.item.id == item.id)
        }
    }
}
