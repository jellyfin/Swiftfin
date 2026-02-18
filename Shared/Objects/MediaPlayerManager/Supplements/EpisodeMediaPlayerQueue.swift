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
import Foundation
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

// TODO: loading, error states
// TODO: watched/status indicators
// TODO: sometimes safe area for CollectionHStack doesn't trigger

@MainActor
class EpisodeMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager? {
        didSet {
            cancellables = []
            guard let manager else { return }
            manager.$playbackItem
                .sink { [weak self] newItem in
                    self?.didReceive(newItem: newItem)
                }
                .store(in: &cancellables)
        }
    }

    let displayTitle: String = L10n.episodes
    let id: String = "EpisodeMediaPlayerQueue"

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

    private var currentAdjacentEpisodesTask: AnyCancellable?
    private let seriesViewModel: SeriesItemViewModel

    init(episode: BaseItemDto) {
        self.seriesViewModel = SeriesItemViewModel(episode: episode)
        super.init()

        seriesViewModel.send(.refresh)
    }

    var videoPlayerBody: some PlatformView {
        EpisodeOverlay(viewModel: seriesViewModel)
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        self.currentAdjacentEpisodesTask = Task {
            await MainActor.run {
                self.nextItem = nil
                self.previousItem = nil
                self.hasNextItem = false
                self.hasPreviousItem = false
            }

            try await self.getAdjacentEpisodes(for: newItem?.baseItem)
        }
        .asAnyCancellable()
    }

    private func getAdjacentEpisodes(for item: BaseItemDto?) async throws {
        guard let item else { return }
        guard let seriesID = item.seriesID, item.type == .episode else { return }

        let parameters = Paths.GetEpisodesParameters(
            userID: userSession.user.id,
            fields: .MinimumFields,
            adjacentTo: item.id!,
            limit: 3
        )
        let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
        let response = try await userSession.client.send(request)

        // 4 possible states:
        //  1 - only current episode
        //  2 - two episodes with next episode
        //  3 - two episodes with previous episode
        //  4 - three episodes with current in middle

        // 1
        guard let items = response.value.items, items.count > 1 else { return }

        var previousItem: BaseItemDto?
        var nextItem: BaseItemDto?

        if items.count == 2 {
            if items[0].id == item.id {
                // 2
                nextItem = items[1]

            } else {
                // 3
                previousItem = items[0]
            }
        } else {
            nextItem = items[2]
            previousItem = items[0]
        }

        var nextProvider: MediaPlayerItemProvider?
        var previousProvider: MediaPlayerItemProvider?

        if let nextItem {
            nextProvider = MediaPlayerItemProvider(item: nextItem) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        }

        if let previousItem {
            previousProvider = MediaPlayerItemProvider(item: previousItem) { item in
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = .zero
                }
            }
        }

        guard !Task.isCancelled else { return }

        await MainActor.run {
            self.nextItem = nextProvider
            self.previousItem = previousProvider
            self.hasNextItem = nextProvider != nil
            self.hasPreviousItem = previousProvider != nil
        }
    }
}

extension EpisodeMediaPlayerQueue {

    private struct EpisodeOverlay: PlatformView {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @State
        private var selection: SeasonItemViewModel.ID?

        private var selectionViewModel: SeasonItemViewModel? {
            guard let selection else { return nil }
            return viewModel.seasons[id: selection]
        }

        private func select(episode: BaseItemDto) {
            let provider = MediaPlayerItemProvider(item: episode) { item in
                let mediaSource = item.mediaSources?.first

                return try await MediaPlayerItem.build(
                    for: item,
                    mediaSource: mediaSource!
                )
            }

            manager.playNewItem(provider: provider)
        }

        var tvOSView: some View {
            TVOSSeasonStackObserver(
                selection: $selection,
                action: select
            )
            .environmentObject(viewModel)
            .onAppear {
                if let seasonID = manager.item.seasonID, let season = viewModel.seasons[id: seasonID] {
                    if season.elements.isEmpty {
                        season.send(.refresh)
                    }
                    selection = season.id
                } else {
                    selection = viewModel.seasons.first?.id
                }
            }
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                CompactSeasonStackObserver(
                    selection: $selection,
                    action: select
                )
            } regularView: {
                RegularSeasonStackObserver(
                    selection: $selection,
                    action: select
                )
            }
            .environmentObject(viewModel)
            .onAppear {
                if let seasonID = manager.item.seasonID, let season = viewModel.seasons[id: seasonID] {
                    if season.elements.isEmpty {
                        season.send(.refresh)
                    }
                    selection = season.id
                } else {
                    selection = viewModel.seasons.first?.id
                }
            }
        }
    }

    private struct CompactSeasonStackObserver: View {

        @EnvironmentObject
        private var seriesViewModel: SeriesItemViewModel

        private let selection: Binding<SeasonItemViewModel.ID?>
        private let action: (BaseItemDto) -> Void

        private var selectionViewModel: SeasonItemViewModel? {
            guard let id = selection.wrappedValue else { return nil }
            return seriesViewModel.seasons[id: id]
        }

        init(
            selection: Binding<SeasonItemViewModel.ID?>,
            action: @escaping (BaseItemDto) -> Void
        ) {
            self.selection = selection
            self.action = action
        }

        private struct _Body: View {

            @ObservedObject
            var selectionViewModel: SeasonItemViewModel

            let action: (BaseItemDto) -> Void

            var body: some View {
                CollectionVGrid(
                    uniqueElements: selectionViewModel.elements,
                    layout: .columns(
                        1,
                        insets: .init(top: 0, leading: 0, bottom: EdgeInsets.edgePadding, trailing: 0)
                    )
                ) { item in
                    EpisodeRow(episode: item) {
                        action(item)
                    }
                    .edgePadding(.horizontal)
                }
            }
        }

        var body: some View {
            if let selectionViewModel {
                _Body(
                    selectionViewModel: selectionViewModel,
                    action: action
                )
            }
        }
    }

    private struct RegularSeasonStackObserver: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var seriesViewModel: SeriesItemViewModel

        private let selection: Binding<SeasonItemViewModel.ID?>
        private let action: (BaseItemDto) -> Void

        private var selectionViewModel: SeasonItemViewModel? {
            guard let id = selection.wrappedValue else { return nil }
            return seriesViewModel.seasons[id: id]
        }

        init(
            selection: Binding<SeasonItemViewModel.ID?>,
            action: @escaping (BaseItemDto) -> Void
        ) {
            self.selection = selection
            self.action = action
        }

        var body: some View {
            Group {
                if let selectionViewModel {
                    PosterHStack(
                        type: .landscape,
                        items: selectionViewModel.elements
                    ) { episode in
                        action(episode)
                    } label: { episode in
                        PosterButton<BaseItemDto>.TitleSubtitleContentView(item: episode)
                            .lineLimit(2, reservesSpace: true)
                    }
                }
            }
            .onReceive(seriesViewModel.$seasons) { newSeasons in
                guard selection.wrappedValue == nil, !newSeasons.isEmpty else { return }
                selection.wrappedValue = newSeasons.first?.id
                newSeasons.first?.send(.refresh)
            }
        }
    }

    private struct TVOSSeasonStackObserver: View {

        @EnvironmentObject
        private var seriesViewModel: SeriesItemViewModel

        private let selection: Binding<SeasonItemViewModel.ID?>
        private let action: (BaseItemDto) -> Void

        private var selectionViewModel: SeasonItemViewModel? {
            guard let id = selection.wrappedValue else { return nil }
            return seriesViewModel.seasons[id: id]
        }

        init(
            selection: Binding<SeasonItemViewModel.ID?>,
            action: @escaping (BaseItemDto) -> Void
        ) {
            self.selection = selection
            self.action = action
        }

        private struct _Body: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState
            @EnvironmentObject
            private var manager: MediaPlayerManager

            #if os(tvOS)
            @EnvironmentObject
            private var focusGuide: FocusGuide

            @FocusState
            private var focusedEpisodeID: String?

            @State
            private var lastFocusedEpisodeID: String?
            #endif

            @ObservedObject
            var selectionViewModel: SeasonItemViewModel

            @StateObject
            private var collectionHStackProxy: CollectionHStackProxy = .init()

            let action: (BaseItemDto) -> Void

            #if os(tvOS)
            private func getContentFocus() {
                if let lastFocusedEpisodeID,
                   selectionViewModel.elements.contains(where: { $0.id == lastFocusedEpisodeID })
                {
                    focusedEpisodeID = lastFocusedEpisodeID
                } else {
                    focusedEpisodeID = selectionViewModel.elements.first?.id
                }
            }
            #endif

            var body: some View {
                Group {
                    switch selectionViewModel.state {
                    case .content:
                        if !selectionViewModel.elements.isEmpty {
                            CollectionHStack(
                                uniqueElements: selectionViewModel.elements,
                                id: \.unwrappedIDHashOrZero,
                                columns: 4
                            ) { episode in
                                EpisodeButton(episode: episode) {
                                    action(episode)
                                }
                                #if os(tvOS)
                                .focused($focusedEpisodeID, equals: episode.id)
                                .padding(.horizontal, 4)
                                #endif
                            }
                            .insets(horizontal: EdgeInsets.edgePadding)
                            .itemSpacing(EdgeInsets.edgePadding)
                            .proxy(collectionHStackProxy)
                            #if os(tvOS)
                                .focusSection()
                                .onChange(of: focusedEpisodeID) { _, newValue in
                                    guard let newValue else { return }
                                    lastFocusedEpisodeID = newValue
                                }
                                .onChange(of: containerState.isPresentingSupplement) { _, newValue in
                                    if newValue {
                                        getContentFocus()
                                    }
                                }
                                .onChange(of: focusGuide.focusedTag) { _, newTag in
                                    if newTag == "supplementContent" {
                                        getContentFocus()
                                    }
                                }
                            #endif
                                .onFirstAppear {
                                        #if os(tvOS)
                                        lastFocusedEpisodeID = manager.item.id
                                        #endif

                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            collectionHStackProxy.scrollTo(
                                                id: manager.item.unwrappedIDHashOrZero,
                                                animated: false
                                            )
                                        }
                                    }
                        }
                    case .initial, .refreshing:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .error:
                        ErrorView(error: ErrorMessage(L10n.unknownError))
                    }
                }
            }
        }

        var body: some View {
            Group {
                if let selectionViewModel {
                    _Body(
                        selectionViewModel: selectionViewModel,
                        action: action
                    )
                }
            }
            .onReceive(seriesViewModel.$seasons) { newSeasons in
                guard selection.wrappedValue == nil, !newSeasons.isEmpty else { return }
                selection.wrappedValue = newSeasons.first?.id
                newSeasons.first?.send(.refresh)
            }
        }
    }

    private struct EpisodePreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected: Bool

        let episode: BaseItemDto

        private var strokeLineWidth: CGFloat {
            #if os(tvOS)
            12
            #else
            8
            #endif
        }

        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.complexSecondary)

                ImageView(episode.imageSource(.primary, maxWidth: 200))
                    .failure {
                        SystemImageContentView(systemName: episode.systemImage)
                    }
            }
            .overlay {
                if isSelected {
                    ContainerRelativeShape()
                        .stroke(
                            accentColor,
                            lineWidth: strokeLineWidth
                        )
                        .clipped()
                }
            }
            .posterStyle(.landscape)
            .posterShadow()
            .hoverEffect(.highlight)
        }
    }

    private struct EpisodeDescription: View {

        let episode: BaseItemDto

        var body: some View {
            DotHStack {
                if let seasonEpisodeLabel = episode.seasonEpisodeLabel {
                    Text(seasonEpisodeLabel)
                }

                if let runtime = episode.runTimeLabel {
                    Text(runtime)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private struct EpisodeRow: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let episode: BaseItemDto
        let action: () -> Void

        private var isCurrentEpisode: Bool {
            manager.item.id == episode.id
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                EpisodePreview(episode: episode)
                    .frame(width: 110)
                    .padding(.vertical, 8)
            } content: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(episode.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    EpisodeDescription(episode: episode)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onSelect(perform: action)
            .isSelected(isCurrentEpisode)
        }
    }

    private struct EpisodeButton: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeItemID: String?

        let episode: BaseItemDto
        let action: () -> Void

        private var isCurrentEpisode: Bool {
            activeItemID == episode.id
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: UIDevice.isTV ? 15 : 5) {
                    EpisodePreview(episode: episode)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(episode.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        EpisodeDescription(episode: episode)
                            .lineLimit(1)
                    }
                }
            }
            #if os(tvOS)
            .buttonStyle(.borderless)
            .buttonBorderShape(.roundedRectangle)
            #endif
            .foregroundStyle(.primary, .secondary)
            .onReceive(manager.$item) { newItem in
                activeItemID = newItem.id
            }
            .isSelected(isCurrentEpisode)
        }
    }
}
