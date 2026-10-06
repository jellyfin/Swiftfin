//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

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
    private let seasonsViewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    init(episode: BaseItemDto) {
        self.seasonsViewModel = PagingLibraryViewModel(
            library: SeasonViewModelLibrary(
                parent: BaseItemDto(id: episode.seriesID, name: episode.seriesName)
            ),
            pageSize: 100
        )
        super.init()

        seasonsViewModel.refresh()
    }

    var videoPlayerBody: some PlatformView {
        EpisodeOverlay(viewModel: seasonsViewModel)
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

        let parameters = try Paths.GetEpisodesParameters(
            userID: authenticatedUser.id,
            adjacentTo: item.id!,
            limit: 3
        )
        let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
        let response = try await send(request)

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
            nextProvider = MediaPlayerItemProvider(item: nextItem) { [weak self] item, modifyItem in
                let bitrate = await self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]
                return try await MediaPlayerItem.build(for: item, requestedBitrate: bitrate) { item in
                    item.userData?.playbackPositionTicks = .zero
                    modifyItem?(&item)
                }
            }
        }

        if let previousItem {
            previousProvider = MediaPlayerItemProvider(item: previousItem) { [weak self] item, modifyItem in
                let bitrate = await self?.manager?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]
                return try await MediaPlayerItem.build(for: item, requestedBitrate: bitrate) { item in
                    item.userData?.playbackPositionTicks = .zero
                    modifyItem?(&item)
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
        private var manager: MediaPlayerManager

        @ObservedObject
        var viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

        @State
        private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectionViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
            guard let selection else { return nil }

            return viewModel.elements[id: selection]
        }

        private func select(episode: BaseItemDto) {
            let provider = MediaPlayerItemProvider(item: episode) { [manager] item, modifyItem in
                try await MediaPlayerItem.build(
                    for: item,
                    requestedBitrate: manager.playbackBitrate,
                    modifyItem: modifyItem
                )
            }

            manager.playNewItem(provider: provider)
        }

        private func selectInitialSeason() {
            if let seasonID = manager.item.seasonID, let season = viewModel.elements[id: seasonID] {
                if season.elements.isEmpty {
                    season.refresh()
                }
                selection = season.id
            } else {
                selection = viewModel.elements.first?.id
            }
        }

        private func setSelectionIfNeeded(seasons: IdentifiedArrayOf<PagingLibraryViewModel<EpisodeLibrary>>) {
            guard selection == nil, !seasons.isEmpty else { return }

            selection = seasons.first?.id
            seasons.first?.refresh()
        }

        @ViewBuilder
        private var seasonView: some View {
            if let selectionViewModel {
                SeasonQueueView(viewModel: selectionViewModel, action: select)
            }
        }

        var iOSView: some View {
            seasonView
                .onAppear { selectInitialSeason() }
                .onReceive(viewModel.$elements) { newSeasons in
                    setSelectionIfNeeded(seasons: newSeasons)
                }
        }

        var tvOSView: some View {
            seasonView
                .onFirstAppear { selectInitialSeason() }
                .onReceive(viewModel.$elements) { newSeasons in
                    setSelectionIfNeeded(seasons: newSeasons)
                }
        }
    }

    private struct SeasonQueueView: PlatformView {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var viewModel: PagingLibraryViewModel<EpisodeLibrary>

        let action: (BaseItemDto) -> Void

        @ViewBuilder
        private func content(errorView: some View) -> some View {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isNotEmpty {
                    VideoPlayer.PosterCollectionView(
                        data: viewModel.elements,
                        currentElementID: manager.item.id.map { .some($0) },
                        isCompact: viewState.isCompact,
                        action: action
                    ) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.displayTitle)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            DotHStack {
                                if let subtitle = item.subtitle {
                                    Text(subtitle)
                                }

                                if let runtime = item.runTimeLabel {
                                    Text(runtime)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

            case .initial, .refreshing:
                EmptyView()

            case .error:
                errorView
            }
        }

        var iOSView: some View {
            content(errorView: CompactOrRegularView(isCompact: viewState.isCompact) {
                ErrorView(error: ErrorMessage(L10n.unknownError))
            } regularView: {
                SeasonErrorView(viewModel: viewModel)
            })
        }

        var tvOSView: some View {
            content(errorView: SeasonErrorView(viewModel: viewModel))
        }
    }

    private struct SeasonErrorView: View {

        @FocusState
        private var isRetryButtonFocused: Bool

        @ObservedObject
        var viewModel: PagingLibraryViewModel<EpisodeLibrary>

        // TODO: Supplements are dismissed on retry, probably due to focus change
        @ViewBuilder
        private var retryButton: some View {
            AlternateLayoutView {
                Label(L10n.retry, systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding()
                    .edgePadding(.horizontal)
                    .frame(height: UIDevice.isTV ? 80 : 40)
            } content: {
                Button {
                    viewModel.refresh()
                } label: {
                    Label(L10n.retry, systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding()
                        .edgePadding(.horizontal)
                }
                .buttonStyle(.supplementAction)
                .focused($isRetryButtonFocused)
                .frame(height: UIDevice.isTV ? 80 : 50)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: EdgeInsets.edgePadding / 2) {
                Text(L10n.unknownError)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxHeight: .infinity, alignment: .topLeading)

                retryButton
            }
            .edgePadding(.horizontal)
            .padding(.vertical, EdgeInsets.edgePadding / 2)
            .background {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Material.thin)
            }
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .edgePadding()
            .focusSection()
        }
    }
}
