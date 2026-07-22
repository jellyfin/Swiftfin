//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

@MainActor
final class MusicMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    @Published
    var hasNextItem = false
    @Published
    var hasPreviousItem = false
    @Published
    var nextItem: MediaPlayerItemProvider?
    @Published
    var previousItem: MediaPlayerItemProvider?
    @Published
    private(set) var isLoading = false

    lazy var hasNextItemPublisher: Published<Bool>.Publisher = $hasNextItem
    lazy var hasPreviousItemPublisher: Published<Bool>.Publisher = $hasPreviousItem
    lazy var nextItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $nextItem
    lazy var previousItemPublisher: Published<MediaPlayerItemProvider?>.Publisher = $previousItem

    let displayTitle: String
    let id: String

    weak var manager: MediaPlayerManager? {
        didSet {
            managerCancellables = []
            currentItemID = manager?.item.id ?? initialItem.id
            isLoading = manager?.state == .loadingItem

            manager?.$item
                .compactMap(\.id)
                .removeDuplicates()
                .sink { [weak self] itemID in
                    self?.currentItemID = itemID
                    self?.updateAdjacentItems()
                }
                .store(in: &managerCancellables)

            manager?.$state
                .sink { [weak self] state in
                    self?.isLoading = state == .loadingItem
                }
                .store(in: &managerCancellables)

            updateAdjacentItems()
        }
    }

    private let initialItem: BaseItemDto
    private let viewModel: PagingLibraryViewModel<MusicTrackLibrary>?

    @Published
    private(set) var currentItemID: String?
    private var items: [BaseItemDto]
    private var managerCancellables: [AnyCancellable] = []

    init(item: BaseItemDto, parent: BaseItemDto? = nil) {
        let resolvedParent = Self.resolveParent(for: item, parent: parent)
        let parentTitle = resolvedParent?.name.flatMap { $0.isNotEmpty ? $0 : nil }
        let albumTitle = item.album.flatMap { $0.isNotEmpty ? $0 : nil }

        self.displayTitle = parentTitle ?? albumTitle ?? L10n.audio
        self.id = "MusicMediaPlayerQueue-\(resolvedParent?.id ?? item.id ?? "unknown")"
        self.initialItem = item
        self.currentItemID = item.id
        self.items = [item]
        self.viewModel = resolvedParent.map {
            PagingLibraryViewModel(
                library: MusicTrackLibrary(parent: $0),
                pageSize: 100
            )
        }

        super.init()

        if let viewModel {
            Publishers.CombineLatest(viewModel.$elements, viewModel.$state)
                .sink { [weak self] elements, state in
                    guard let self, state == .content else { return }
                    self.items = Array(elements)
                    self.updateAdjacentItems()
                }
                .store(in: &cancellables)

            viewModel.refresh()
        }

        updateAdjacentItems()
    }

    var videoPlayerBody: some PlatformView {
        InlinePlatformView {
            if let viewModel = self.viewModel {
                MusicQueueView(
                    queue: self,
                    viewModel: viewModel
                )
            } else {
                MusicQueueContent(
                    queue: self,
                    items: self.items
                )
            }
        } tvOSView: {
            EmptyView()
        }
    }

    private static func resolveParent(for item: BaseItemDto, parent: BaseItemDto?) -> BaseItemDto? {
        if let parent, parent.type == .musicAlbum || parent.type == .musicArtist {
            return parent
        }

        guard let albumID = item.albumID else { return nil }

        return BaseItemDto(
            id: albumID,
            name: item.album,
            type: .musicAlbum
        )
    }

    private func updateAdjacentItems() {
        guard let currentItemID,
              let currentIndex = items.firstIndex(where: { $0.id == currentItemID })
        else {
            setAdjacentItems(previous: nil, next: nil)
            return
        }

        let previous = currentIndex > items.startIndex ? items[items.index(before: currentIndex)] : nil
        let nextIndex = items.index(after: currentIndex)
        let next = nextIndex < items.endIndex ? items[nextIndex] : nil

        setAdjacentItems(previous: previous, next: next)
    }

    private func setAdjacentItems(previous: BaseItemDto?, next: BaseItemDto?) {
        previousItem = previous.map(makeProvider)
        nextItem = next.map(makeProvider)
        hasPreviousItem = previousItem != nil
        hasNextItem = nextItem != nil
    }

    private func makeProvider(for item: BaseItemDto) -> MediaPlayerItemProvider {
        MediaPlayerItemProvider(item: item) { [weak self] item in
            let bitrate = await self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]

            return try await MediaPlayerItem.build(
                for: item,
                requestedBitrate: bitrate
            ) {
                $0.userData?.playbackPositionTicks = .zero
            }
        }
    }

    private func play(_ item: BaseItemDto) {
        guard !isLoading,
              manager?.state != .loadingItem,
              item.id != currentItemID
        else {
            return
        }

        manager?.playNewItem(provider: makeProvider(for: item))
    }
}

extension MusicMediaPlayerQueue {

    private struct MusicQueueView: View {

        @ObservedObject
        var queue: MusicMediaPlayerQueue
        @ObservedObject
        var viewModel: PagingLibraryViewModel<MusicTrackLibrary>

        @ViewBuilder
        private var content: some View {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    ContentUnavailableView(
                        L10n.noItems.localizedCapitalized,
                        systemImage: "rectangle.on.rectangle.slash"
                    )
                } else {
                    MusicQueueContent(
                        queue: queue,
                        items: Array(viewModel.elements)
                    )
                }
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        var body: some View {
            content
                .refreshable {
                    viewModel.refresh()
                }
        }
    }

    private struct MusicQueueContent: View {

        @Environment(\.dismiss)
        private var dismiss

        @ObservedObject
        var queue: MusicMediaPlayerQueue

        let items: [BaseItemDto]

        var body: some View {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element) { offset, item in
                            MusicQueueRow(
                                item: item,
                                fallbackIndex: offset + 1,
                                isCurrent: queue.currentItemID == item.id,
                                isEnabled: !queue.isLoading
                            ) {
                                guard !queue.isLoading, queue.currentItemID != item.id else { return }
                                queue.play(item)
                                dismiss()
                            }
                            .id(scrollID(for: item))
                        }
                    }
                    .withViewContext(.isListRowSeparatorVisible)
                    .padding(.bottom, EdgeInsets.edgePadding)
                }
                .onAppear {
                    scrollToCurrent(with: scrollProxy)
                }
                .backport
                .onChange(of: queue.currentItemID) { _, _ in
                    withAnimation {
                        scrollToCurrent(with: scrollProxy)
                    }
                }
            }
        }

        private func scrollID(for item: BaseItemDto) -> AnyHashable {
            if let itemID = item.id {
                return AnyHashable(itemID)
            }

            return AnyHashable(item)
        }

        private func scrollToCurrent(with scrollProxy: ScrollViewProxy) {
            guard let currentItem = items.first(where: { $0.id == queue.currentItemID }) else { return }
            scrollProxy.scrollTo(scrollID(for: currentItem), anchor: .center)
        }
    }

    private struct MusicQueueRow: View {

        let item: BaseItemDto
        let fallbackIndex: Int
        let isCurrent: Bool
        let isEnabled: Bool
        let action: () -> Void

        private var artists: String? {
            guard let artists = item.artists?.joined(separator: ", "), artists.isNotEmpty else {
                return item.albumArtist
            }

            return artists
        }

        private var trackIndex: String {
            item.indexNumber?.formatted() ?? fallbackIndex.formatted()
        }

        var body: some View {
            ListRow(
                insets: .init(vertical: 12, horizontal: EdgeInsets.edgePadding)
            ) {
                Group {
                    if isCurrent {
                        Image(systemName: "waveform")
                            .accessibilityHidden(true)
                    } else {
                        Text(trackIndex)
                            .monospacedDigit()
                    }
                }
                .font(.callout)
                .foregroundStyle(isCurrent ? .primary : .secondary)
                .frame(width: 24)
            } content: {
                HStack(spacing: 12) {
                    PosterImage(
                        item: item,
                        type: .square,
                        size: .extraSmall
                    )
                    .frame(width: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.displayTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        if let artists, artists.isNotEmpty {
                            Text(artists)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let runtime = item.runtime {
                        Text(runtime, format: .runtime)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            } action: {
                action()
            }
            .disabled(!isEnabled)
            .background(isCurrent ? Color.secondarySystemFill : Color.clear)
            .accessibilityLabel(item.displayTitle)
            .accessibilityValue(isCurrent ? L10n.active : .empty)
            .accessibilityHint(isCurrent || !isEnabled ? .empty : L10n.play)
        }
    }
}

#endif
