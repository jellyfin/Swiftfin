//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import Defaults
import Foundation
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

// TODO: loading, error states
// TODO: season selection

class EpisodeMediaPlayerQueue: ViewModel, MediaPlayerQueue {

    weak var manager: MediaPlayerManager?

    let displayTitle: String = L10n.episodes
    let id: String = "EpisodeMediaPlayerQueue"

    var nextItem: MediaPlayerItemProvider?
    var previousItem: MediaPlayerItemProvider?

    private let seriesViewModel: SeriesItemViewModel

    init(episode: BaseItemDto) {
        self.seriesViewModel = SeriesItemViewModel(episode: episode)
        super.init()

        Task {
            await seriesViewModel.send(.refresh)
        }
    }

    private func setup(with manager: MediaPlayerManager) {
        cancellables = []

        //        manager.$playbackItem.sink(receiveValue: playbackItemDidChange).store(in: &cancellables)
        //        manager.$seconds.sink(receiveValue: secondsDidChange).store(in: &cancellables)
        //        manager.$playbackRequestStatus.sink(receiveValue: playbackStatusDidChange).store(in: &cancellables)
    }

    var videoPlayerBody: some PlatformView {
        EpisodeOverlay(viewModel: seriesViewModel)
    }
}

extension EpisodeMediaPlayerQueue {

    private struct EpisodeOverlay: PlatformView {

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

        var tvOSView: some View { EmptyView() }

        var iOSView: some View {
            let shouldBeCompact: (CGSize) -> Bool = { size in
                size.width < 300 || size.isPortrait
            }

            CompactOrRegularView(shouldBeCompact: shouldBeCompact) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .onAppear {
                if let seasonID = manager.item.seasonID, let season = viewModel.seasons[id: seasonID] {
                    season.send(.refresh)
                    selection = season.id
                } else {
                    selection = viewModel.seasons.first?.id
                }
            }
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            if let selectionViewModel {
                CompactSeasonStackObserver(selectionViewModel: selectionViewModel)
            }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            if let selectionViewModel {
                RegularSeasonStackObserver(selectionViewModel: selectionViewModel)
            }
        }
    }

    private struct CompactSeasonStackObserver: View {

        @ObservedObject
        var selectionViewModel: SeasonItemViewModel

        var body: some View {
            CollectionVGrid(
                uniqueElements: selectionViewModel.elements,
                layout: .columns(
                    1,
                    insets: .init(top: 0, leading: 0, bottom: EdgeInsets.edgePadding, trailing: 0)
                )
            ) { item in
                EpisodeRow(episode: item) {}
                    .edgePadding(.horizontal)
            }
        }
    }

    private struct RegularSeasonStackObserver: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @ObservedObject
        var selectionViewModel: SeasonItemViewModel

        var body: some View {
            CollectionHStack(
                uniqueElements: selectionViewModel.elements,
                id: \.unwrappedIDHashOrZero
            ) { item in
                EpisodeButton(episode: item) {}
                    .frame(height: 150)
            }
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .frame(height: 150)
        }
    }

    private struct EpisodePreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected: Bool

        @State
        private var contentSize: CGSize = .zero

        let episode: BaseItemDto

        var body: some View {
            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(episode.imageSource(.primary, maxWidth: 200))
                    .failure {
                        ZStack {
                            Rectangle()
                                .fill(Material.ultraThinMaterial)

                            SystemImageContentView(systemName: episode.systemImage)
                                .background(color: Color.clear)
                        }
                    }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: contentSize.width / 30)
                        .stroke(accentColor, lineWidth: 8)
                }
            }
            .posterStyle(.landscape)
            .trackingSize($contentSize)
        }
    }

    private struct EpisodeRow: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var contentSize: CGSize = .zero

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
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(episode.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

//                        accessoryView
//                            .font(.caption)
//                            .foregroundColor(Color(UIColor.lightGray))
                    }

                    Spacer()
                }
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

        @State
        private var contentSize: CGSize = .zero

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
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .frame(height: 15)

                        Text(episode.seasonEpisodeLabel ?? .emptyDash)
                            .frame(height: 20)
                            .foregroundStyle(Color(UIColor.systemBlue))
                            .padding(.horizontal, 4)
                            .background {
                                Color(.darkGray)
                                    .opacity(0.2)
                                    .cornerRadius(4)
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .trackingSize($contentSize)
            .isSelected(isCurrentEpisode)
        }
    }
}
