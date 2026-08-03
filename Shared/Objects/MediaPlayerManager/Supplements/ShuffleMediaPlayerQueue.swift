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

    /// Shuffle always advances; the next-episode auto-play setting only
    /// governs sequential episode playback.
    let autoPlayNextItem: Bool = true

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
    private var fillTask: AnyCancellable?

    /// IDs already seen, excluded from the fill request so the server's
    /// re-randomized query doesn't return duplicates.
    private let excludeIDs: [String]
    private let parentID: String?
    private let filters: ItemFilterCollection?

    /// The playable item types a container can shuffle across.
    private static let shuffleableItemTypes: [BaseItemKind] = [.episode, .movie, .video, .musicVideo, .trailer]

    /// Items fetched per request while hunting for the first playable item.
    private static let pageSize = 20

    /// Upper bound on the shuffled queue's size. The server has no stable random
    /// seed, so instead of paging (which re-randomizes every request) the queue is
    /// topped up once to this cap using `excludeItemIDs` to avoid duplicates.
    private static let targetQueueSize = 100

    /// Bounds the IDs accumulated while hunting for the first playable item,
    /// keeping the request URL's `excludeItemIDs` list within proxy limits.
    private static let maxExcludeIDs = targetQueueSize

    private static let maxFillAttempts = 3

    /// Fetches random children until one is playable (a page can filter down to
    /// nothing, e.g. all missing episodes) and returns the initial item to play
    /// alongside a queue that lazily fills the rest in the background.
    static func build(
        for parent: BaseItemDto,
        filters: ItemFilterCollection? = nil
    ) async throws -> (firstItem: BaseItemDto, queue: ShuffleMediaPlayerQueue)? {
        guard let userSession = Container.shared.currentUserSession() else {
            throw ErrorMessage(L10n.unknownError)
        }

        var elements: [BaseItemDto] = []
        var excludeIDs: [String] = []
        var serverExhausted = false

        while elements.isEmpty, !serverExhausted, excludeIDs.count < maxExcludeIDs {
            let (page, returnedIDs) = try await fetchPage(
                parentID: parent.id,
                filters: filters,
                excludeIDs: excludeIDs,
                limit: pageSize,
                userSession: userSession
            )

            elements = page
            excludeIDs.append(contentsOf: returnedIDs)
            serverExhausted = returnedIDs.count < pageSize
        }

        guard let firstItem = elements.first else { return nil }

        let queue = ShuffleMediaPlayerQueue(
            elements: elements,
            excludeIDs: excludeIDs,
            parentID: parent.id,
            filters: filters,
            serverExhausted: serverExhausted
        )
        return (firstItem, queue)
    }

    private init(
        elements: [BaseItemDto],
        excludeIDs: [String],
        parentID: String?,
        filters: ItemFilterCollection?,
        serverExhausted: Bool
    ) {
        self.elements = elements
        self.excludeIDs = excludeIDs
        self.parentID = parentID
        self.filters = filters
        super.init()

        updateAdjacentItems()

        if !serverExhausted {
            fillRemainingItems()
        }
    }

    var videoPlayerBody: some PlatformView {
        ShuffleOverlay(queue: self)
    }

    /// Tops the queue up to `targetQueueSize` with a single follow-up request while
    /// the first item is already playing. `self` is only touched after the network
    /// work: the task must not keep a dismissed player's queue alive, since the
    /// queue's deinit is what cancels `fillTask`.
    private func fillRemainingItems() {
        guard let userSession else { return }

        let limit = Self.targetQueueSize - elements.count

        fillTask = Task { [weak self, parentID, filters, excludeIDs] in
            for attempt in 1 ... Self.maxFillAttempts {
                guard !Task.isCancelled else { return }

                do {
                    let (page, _) = try await Self.fetchPage(
                        parentID: parentID,
                        filters: filters,
                        excludeIDs: excludeIDs,
                        limit: limit,
                        userSession: userSession
                    )

                    guard !Task.isCancelled else { return }
                    self?.append(contentsOf: page)
                    return
                } catch {
                    guard !Task.isCancelled, !(error is CancellationError) else { return }

                    guard attempt < Self.maxFillAttempts else {
                        self?.logger.error("Error filling shuffle queue: \(error.localizedDescription)")
                        return
                    }

                    try? await Task.sleep(for: .seconds(2))
                }
            }
        }
        .asAnyCancellable()
    }

    private func append(contentsOf newElements: [BaseItemDto]) {
        guard newElements.isNotEmpty else { return }

        elements.append(contentsOf: newElements)
        updateAdjacentItems()
    }

    /// Requests up to `limit` random children, excluding the given IDs. Returns the
    /// playable items alongside all returned IDs, so the caller can exclude every
    /// seen item and guarantee forward progress across requests.
    private static func fetchPage(
        parentID: String?,
        filters: ItemFilterCollection?,
        excludeIDs: [String],
        limit: Int,
        userSession: UserSession
    ) async throws -> (items: [BaseItemDto], returnedIDs: [String]) {
        var parameters = Paths.GetItemsParameters()

        if let filters {
            parameters = filters.apply(to: parameters)
        }

        // filter item types narrow the shuffleable set, never widen it
        let itemTypes: [BaseItemKind] = if let filterTypes = filters?.itemTypes, filterTypes.isNotEmpty {
            filterTypes.filter { shuffleableItemTypes.contains($0) }
        } else {
            shuffleableItemTypes
        }

        // an empty list would be sent as "no type filter"
        guard itemTypes.isNotEmpty else { return ([], []) }

        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isRecursive = true
        parameters.parentID = parentID
        parameters.includeItemTypes = itemTypes

        // shuffle overrides any sort the filters applied
        parameters.sortBy = [.random]
        parameters.sortOrder = nil

        parameters.limit = limit
        parameters.userID = userSession.user.id

        if excludeIDs.isNotEmpty {
            parameters.excludeItemIDs = excludeIDs
        }

        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)

        let returned = response.value.items ?? []
        return (returned.filter(\.isPlayable), returned.compactMap(\.id))
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

    /// Builds a provider that plays the item from the beginning, resolving the
    /// requested bitrate lazily when the item is built.
    func makeProvider(for item: BaseItemDto) -> MediaPlayerItemProvider {
        MediaPlayerItemProvider(item: item) { [weak self] item, modifyItem in
            let bitrate = await self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]
            return try await MediaPlayerItem.build(for: item, requestedBitrate: bitrate) { item in
                item.userData?.playbackPositionTicks = .zero
                modifyItem?(&item)
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
            manager.playNewItem(provider: queue.makeProvider(for: item))
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
