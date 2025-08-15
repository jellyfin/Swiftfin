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

    @ViewBuilder
    func videoPlayerBody() -> some PlatformView {
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
            } else {
                Color.red
                    .opacity(0.2)
            }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            if let selectionViewModel {
                RegularSeasonStackObserver(selectionViewModel: selectionViewModel)
            } else {
                Color.red
                    .opacity(0.2)
            }
        }
    }

    private struct CompactSeasonStackObserver: View {

        @ObservedObject
        var selectionViewModel: SeasonItemViewModel

        var body: some View {
            CollectionVGrid(
                uniqueElements: selectionViewModel.elements,
                layout: .columns(1, insets: .zero)
            ) { item in
                EpisodeButton(item: item, isCompact: true)
                    .frame(height: 100)
                    .edgePadding(.horizontal)
            }
        }
    }

    private struct RegularSeasonStackObserver: View {

        @ObservedObject
        var selectionViewModel: SeasonItemViewModel

        var body: some View {
            CollectionHStack(
                uniqueElements: selectionViewModel.elements,
                id: \.unwrappedIDHashOrZero
            ) { item in
                EpisodeButton(item: item, isCompact: false)
                    .frame(height: 150)
            }
            .insets(horizontal: .zero)
            .frame(height: 150)
            .onAppear {
                selectionViewModel.send(.refresh)
            }
        }
    }

    private struct EpisodeButton: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager
        
        @State
        private var contentSize: CGSize = .zero

        let item: BaseItemDto
        let isCompact: Bool
        
        private var isCurrentEpisode: Bool {
            manager.item.id == item.id
        }

        @ViewBuilder
        private func withAlignmentStack(@ViewBuilder content: @escaping () -> some View) -> some View {
            if isCompact {
                HStack(spacing: 5) { content() }
            } else {
                VStack(alignment: .leading, spacing: 5) { content() }
            }
        }

        var body: some View {
            Button {
//                manager.send(.playNewBaseItem(item: item))
            } label: {
                withAlignmentStack {
                    AlternateLayoutView {
                        Color.clear
                    } content: {
                        ImageView(item.imageSource(.primary, maxWidth: 150))
                            .failure {
                                ZStack {
                                    Rectangle()
                                        .fill(Material.ultraThinMaterial)

                                    SystemImageContentView(systemName: item.systemImage)
                                        .background(color: Color.clear)
                                }
                            }
                    }
                    .overlay {
                        if isCurrentEpisode {
                            RoundedRectangle(cornerRadius: contentSize.width / 30)
                                .stroke(accentColor, lineWidth: 8)
                        }
                    }
                    .posterStyle(.landscape, contentMode: isCompact ? .fit : .fill)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.displayTitle)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                            .frame(height: 15)

                        Text(item.seasonEpisodeLabel ?? .emptyDash)
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
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            .trackingSize($contentSize)
        }
    }
}
