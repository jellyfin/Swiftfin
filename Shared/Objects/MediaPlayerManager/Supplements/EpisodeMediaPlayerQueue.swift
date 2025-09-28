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

        var tvOSView: some View { EmptyView() }

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

        private struct _Body: View {

            @Environment(\.safeAreaInsets)
            private var safeAreaInsets: EdgeInsets

            @ObservedObject
            var selectionViewModel: SeasonItemViewModel

            let action: (BaseItemDto) -> Void

            var body: some View {
                CollectionHStack(
                    uniqueElements: selectionViewModel.elements,
                    id: \.unwrappedIDHashOrZero
                ) { item in
                    EpisodeButton(episode: item) {
                        action(item)
                    }
                    .frame(height: 150)
                }
                .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            }
        }

        var body: some View {
            if let selectionViewModel {
                _Body(
                    selectionViewModel: selectionViewModel,
                    action: action
                )
                .frame(height: 150)
            }
        }

        // TODO: make experimental setting to enable
        private struct _ButtonStack: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState
            @EnvironmentObject
            private var manager: MediaPlayerManager
            @EnvironmentObject
            private var seriesViewModel: SeriesItemViewModel

            let selection: Binding<SeasonItemViewModel.ID?>
            let selectionViewModel: SeasonItemViewModel

            init(
                selection: Binding<SeasonItemViewModel.ID?>,
                selectionViewModel: SeasonItemViewModel
            ) {
                self.selection = selection
                self.selectionViewModel = selectionViewModel
            }

            var body: some View {
                VStack {
                    Menu {
                        ForEach(seriesViewModel.seasons, id: \.season.id) { season in
                            Button {
                                selection.wrappedValue = season.id
                                if season.elements.isEmpty {
                                    season.send(.refresh)
                                }
                            } label: {
                                if season.id == selection.wrappedValue {
                                    Label(season.season.displayTitle, systemImage: "checkmark")
                                } else {
                                    Text(season.season.displayTitle)
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Label(selectionViewModel.season.displayTitle, systemImage: "chevron.down")
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxHeight: .infinity)

                    Button {
                        guard let nextItem = manager.queue?.nextItem else { return }
                        manager.playNewItem(provider: nextItem)
                        manager.setPlaybackRequestStatus(status: .playing)
                        containerState.select(supplement: nil)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Label("Next", systemImage: "forward.end.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxHeight: .infinity)

                    Button {
                        guard let previousItem = manager.queue?.previousItem else { return }
                        manager.playNewItem(provider: previousItem)
                        manager.setPlaybackRequestStatus(status: .playing)
                        containerState.select(supplement: nil)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .foregroundStyle(.white)

                            Label("Previous", systemImage: "backward.end.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(width: 150)
                .edgePadding(.horizontal)
//                .padding(.trailing, safeAreaInsets.trailing)
            }
        }
    }

    private struct EpisodePreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected: Bool

        let episode: BaseItemDto

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
                            lineWidth: 8
                        )
                        .clipped()
                }
            }
            .posterStyle(.landscape)
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

        @Default(.accentColor)
        private var accentColor

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

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let episode: BaseItemDto
        let action: () -> Void

        private var isCurrentEpisode: Bool {
            manager.item.id == episode.id
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 5) {
                    EpisodePreview(episode: episode)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(episode.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                            .frame(height: 15)

                        EpisodeDescription(episode: episode)
                            .frame(height: 20, alignment: .top)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .foregroundStyle(.primary, .secondary)
            .isSelected(isCurrentEpisode)
        }
    }
}
