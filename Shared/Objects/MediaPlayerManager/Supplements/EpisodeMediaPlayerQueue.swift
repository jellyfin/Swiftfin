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

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedEpisodeID: String?

        @ObservedObject
        var viewModel: SeriesItemViewModel

        @State
        private var selection: SeasonItemViewModel.ID?

        @StateObject
        private var collectionHStackProxy: CollectionHStackProxy = .init()

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

        private func selectInitialSeason() {
            if let seasonID = manager.item.seasonID, let season = viewModel.seasons[id: seasonID] {
                if season.elements.isEmpty {
                    season.send(.refresh)
                }
                selection = season.id
            } else {
                selection = viewModel.seasons.first?.id
            }
        }

        private func setSelectionIfNeeded(seasons: IdentifiedArrayOf<SeasonItemViewModel>) {
            guard selection == nil, !seasons.isEmpty else { return }
            selection = seasons.first?.id
            seasons.first?.send(.refresh)
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .onAppear { selectInitialSeason() }
            .onReceive(viewModel.$seasons) { newSeasons in
                setSelectionIfNeeded(seasons: newSeasons)
            }
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            if let selectionViewModel {
                EpisodeSeason(season: selectionViewModel) { season in
                    switch season.state {
                    case .content:
                        if !season.elements.isEmpty {
                            CollectionVGrid(
                                uniqueElements: season.elements,
                                layout: .columns(
                                    1,
                                    insets: .init(EdgeInsets.edgePadding)
                                )
                            ) { item in
                                EpisodeRow(episode: item) {
                                    select(episode: item)
                                }
                            }
                        }
                    case .initial, .refreshing:
                        CollectionVGrid(
                            count: 1,
                            layout: .columns(
                                1,
                                insets: .init(EdgeInsets.edgePadding)
                            )
                        ) { _ in
                            EpisodeRowPlaceholder()
                        }
                    case .error:
                        ErrorView(error: ErrorMessage(L10n.unknownError))
                    }
                }
            }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            if let selectionViewModel {
                EpisodeSeason(season: selectionViewModel) { season in
                    switch season.state {
                    case .content:
                        if !season.elements.isEmpty {
                            CollectionHStack(
                                uniqueElements: season.elements,
                                id: \.unwrappedIDHashOrZero,
                                layout: .minimumWidth(columnWidth: 170, rows: 1)
                            ) { item in
                                EpisodeButton(episode: item) {
                                    select(episode: item)
                                }
                            }
                            .clipsToBounds(false)
                            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
                            .itemSpacing(EdgeInsets.edgePadding / 2)
                            .scrollBehavior(.continuousLeadingEdge)
                        }
                    case .initial, .refreshing:
                        CollectionHStack(
                            count: Int.random(in: 1 ..< 3),
                            minWidth: 170,
                            rows: 1
                        ) { _ in
                            SupplementLoadingButton()
                        }
                        .clipsToBounds(false)
                        .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
                        .itemSpacing(EdgeInsets.edgePadding / 2)
                        .scrollBehavior(.continuousLeadingEdge)
                    case .error:
                        ErrorView(error: ErrorMessage(L10n.unknownError))
                    }
                }
            }
        }

        var tvOSView: some View {
            tvOSContent
                .onAppear { selectInitialSeason() }
                .onReceive(viewModel.$seasons) { newSeasons in
                    setSelectionIfNeeded(seasons: newSeasons)
                }
        }

        @ViewBuilder
        private var tvOSContent: some View {
            #if os(tvOS)
            if let selectionViewModel {
                EpisodeSeason(season: selectionViewModel) { season in
                    switch season.state {
                    case .content:
                        if !season.elements.isEmpty {
                            CollectionVGrid(
                                uniqueElements: season.elements,
                                id: \.unwrappedIDHashOrZero,
                                layout: .columns(
                                    5,
                                    insets: .init(EdgeInsets.edgePadding),
                                    itemSpacing: EdgeInsets.edgePadding,
                                    lineSpacing: EdgeInsets.edgePadding
                                )
                            ) { episode in
                                EpisodeButton(episode: episode) {
                                    select(episode: episode)
                                }
                                .focused($focusedEpisodeID, equals: episode.id)
                                .padding(.horizontal, 4)
                            }
                            .ignoresSafeArea(.container, edges: .horizontal)
                            .focusSection()
                        }
                    case .initial, .refreshing, .error:
                        CollectionVGrid(
                            count: 1,
                            layout: .columns(
                                5,
                                insets: .init(EdgeInsets.edgePadding),
                                itemSpacing: EdgeInsets.edgePadding,
                                lineSpacing: EdgeInsets.edgePadding
                            )
                        ) { _ in
                            switch season.state {
                            case .error:
                                SupplementEmptyButton()
                            default:
                                SupplementLoadingButton()
                            }
                        }
                        .ignoresSafeArea(.container, edges: .horizontal)
                    }
                }
            }
            #endif
        }
    }

    private struct EpisodeSeason<Content: View>: View {

        @ObservedObject
        var season: SeasonItemViewModel

        @ViewBuilder
        let content: (SeasonItemViewModel) -> Content

        var body: some View {
            content(season)
        }
    }

    private struct EpisodePreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

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
                            lineWidth: UIDevice.isTV ? 12 : 8
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

    private struct EpisodeRowPlaceholder: View {

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                Rectangle()
                    .fill(.complexSecondary)
                    .frame(width: 110)
                    .padding(.vertical, 8)
                    .posterStyle(.landscape)
                    .posterShadow()
                    .hoverEffect(.highlight)
            } content: {
                VStack(alignment: .leading, spacing: 5) {
                    Text(String.random(count: 10 ..< 20))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2, reservesSpace: true)
                        .multilineTextAlignment(.leading)
                        .redacted(reason: .placeholder)

                    DotHStack {
                        Text(String.random(count: 1 ..< 2))
                        Text(String.random(count: 2 ..< 3))
                    }
                    .redacted(reason: .placeholder)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private struct EpisodeButton: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let episode: BaseItemDto
        let action: () -> Void

        var body: some View {
            SupplementPosterButton(
                item: episode,
                isSelected: manager.item.id == episode.id,
                action: action
            ) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(episode.displayTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1, reservesSpace: true)

                    EpisodeDescription(episode: episode)
                        .font(UIDevice.isTV ? .caption : .subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1, reservesSpace: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
