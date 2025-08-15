//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
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
        _View(viewModel: seriesViewModel)
    }
}

extension EpisodeMediaPlayerQueue {

    struct SeasonStackObserver: View {

        @ObservedObject
        var selectionViewModel: SeasonItemViewModel

        var body: some View {
            CollectionHStack(
                uniqueElements: selectionViewModel.elements,
                id: \.unwrappedIDHashOrZero
            ) { item in
                EpisodeButton(item: item)
                    .frame(height: 150)
            }
            .insets(horizontal: .zero)
            .debugBackground(.green.opacity(0.5))
            .frame(height: 150)
            .onAppear {
                selectionViewModel.send(.refresh)
            }
        }
    }

    private struct _View: PlatformView {

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
            ZStack {
                if let selectionViewModel {
                    SeasonStackObserver(selectionViewModel: selectionViewModel)
                } else {
                    CollectionHStack(count: Int.random(in: 2 ..< 5)) { _ in
                        Color.secondarySystemFill
                            .opacity(0.75)
                            .posterStyle(.landscape)
                            .frame(height: 150)
                    }
                    .insets(horizontal: .zero)
                }
            }
            .frame(height: 150)
            .onAppear {
                if let seasonID = manager.item.seasonID, let season = viewModel.seasons[id: seasonID] {
                    selection = season.id
                } else {
                    selection = viewModel.seasons.first?.id
                }
            }
//            .onReceive(viewModel.playButtonItem.publisher) { newValue in
//                if let season = viewModel.seasons[id: newValue.seasonID.hashValueOrZero] {
//                    selection = season.id
//                } else {
//                    selection = viewModel.seasons.first?.id
//                }
//            }
//            .onChange(of: selection) { newValue in
//                guard let newValue else {
//                    return
//                }
//
//                manager.queue?.items =
//            }
//            .onChange(of: selection) { newValue in
//                guard let newValue else { return }
//                selectionViewModel = viewModel.seasons[id: newValue]
//                guard let selection else { return nil }
//                return viewModel.seasons[id: selection]
//            }
//            .onChange(of: selection) { newValue in
//                guard let newValue else {
//                    manager.queue?.items.removeAll()
//                    return
//                }
//
//                manager.queue?.items = newValue.elements
//
//                if newValue.state == .initial {
//                    newValue.send(.refresh)
//                }
//            }
//            .onChange(of: selection?.elements) { newValue in
//                guard let newValue else { return }
//
//                manager.queue?.items = newValue
//            }
        }
    }

    struct EpisodeButton: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let item: BaseItemDto

        var body: some View {
            Button {
//                manager.send(.playNewBaseItem(item: item))
            } label: {
                VStack(alignment: .leading, spacing: 5) {
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
                        if manager.item.id == item.id {
                            Rectangle()
                                .stroke(accentColor, lineWidth: 8)
                                .cornerRadius(ratio: 1 / 30, of: \.width)
                        }
                    }
                    .aspectRatio(1.77, contentMode: .fill)
                    .posterBorder()
                    .cornerRadius(ratio: 1 / 30, of: \.width)

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
                .font(.subheadline.weight(.semibold))
            }
        }
    }
}
