//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeContentGroup: ContentGroup, Identifiable {

    let id: String
    let series: BaseItemDto
    let viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

    var displayTitle: String {
        L10n.episodes
    }

    var _shouldBeResolved: Bool {
        viewModel.elements.isNotEmpty
    }

    init(series: BaseItemDto) {
        self.id = "\(series.id ?? "series")-episode-selector"
        self.series = series
        self.viewModel = .init(library: SeasonViewModelLibrary(series: series), pageSize: 100)
    }

    func body(with viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>) -> Body {
        Body(viewModel: viewModel)
    }

    struct Body: View {

        @ObservedObject
        var viewModel: PagingLibraryViewModel<SeasonViewModelLibrary>

        @State
        private var selection: PagingLibraryViewModel<EpisodeLibrary>.ID?

        private var selectedSeasonViewModel: PagingLibraryViewModel<EpisodeLibrary>? {
            viewModel.elements.first { $0.id == selection }
        }

        private var columns: [GridItem] {
            [
                GridItem(
                    .adaptive(minimum: UIDevice.isTV ? 360 : 220, maximum: UIDevice.isTV ? 520 : 320),
                    spacing: UIDevice.isTV ? 40 : 16
                ),
            ]
        }

        @ViewBuilder
        private var seasonSelectorView: some View {
            if viewModel.elements.count <= 1 {
                Text(selectedSeasonViewModel?.library.parent.displayTitle ?? L10n.episodes)
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Menu {
                    ForEach(viewModel.elements) { seasonViewModel in
                        Button {
                            selection = seasonViewModel.id
                        } label: {
                            if seasonViewModel.id == selection {
                                Label(seasonViewModel.library.parent.displayTitle, systemImage: "checkmark")
                            } else {
                                Text(seasonViewModel.library.parent.displayTitle)
                            }
                        }
                    }
                } label: {
                    Label(
                        selectedSeasonViewModel?.library.parent.displayTitle ?? L10n.episodes,
                        systemImage: "chevron.down"
                    )
                    #if os(iOS)
                    .labelStyle(.episodeSelector)
                    #endif
                }
            }
        }

        @ViewBuilder
        private func episodesView(_ seasonViewModel: PagingLibraryViewModel<EpisodeLibrary>) -> some View {
            switch seasonViewModel.state {
            case .content:
                if seasonViewModel.elements.isEmpty {
                    ContentUnavailableView(L10n.noResults, systemImage: "rectangle.on.rectangle.slash")
                        .edgePadding(.horizontal)
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: UIDevice.isTV ? 40 : 16) {
                        ForEach(seasonViewModel.elements) { episode in
                            EpisodeCard(episode: episode)
                        }
                    }
                    .edgePadding(.horizontal)
                }
            case .error:
                seasonViewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }

        var body: some View {
            VStack(alignment: .leading, spacing: UIDevice.isTV ? 24 : 12) {
                seasonSelectorView
                    .edgePadding(.horizontal)

                if let selectedSeasonViewModel {
                    episodesView(selectedSeasonViewModel)
                        .onFirstAppear {
                            if selectedSeasonViewModel.state == .initial {
                                selectedSeasonViewModel.refresh()
                            }
                        }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .onFirstAppear {
                if selection == nil {
                    selection = viewModel.elements.first?.id
                }
            }
            .onChange(of: viewModel.elements.count) { _ in
                if selection == nil || !viewModel.elements.contains(where: { $0.id == selection }) {
                    selection = viewModel.elements.first?.id
                }
            }
            .onChange(of: selection) { _ in
                guard let selectedSeasonViewModel, selectedSeasonViewModel.state == .initial else { return }
                selectedSeasonViewModel.refresh()
            }
        }

        private struct EpisodeCard: View {

            @Default(.Customization.Indicators.showPlayed)
            private var showPlayed

            @Namespace
            private var namespace

            @Router
            private var router

            let episode: BaseItemDto

            @ViewBuilder
            private var overlayView: some View {
                if let progressLabel = episode.progressLabel {
                    LandscapePosterProgressBar(
                        title: progressLabel,
                        progress: (episode.userData?.playedPercentage ?? 0) / 100
                    )
                } else if episode.userData?.isPlayed ?? false, showPlayed {
                    WatchedIndicator(size: UIDevice.isTV ? 45 : 25)
                }
            }

            private var episodeContent: String {
                if episode.isUnaired {
                    episode.airDateLabel ?? L10n.noOverviewAvailable
                } else {
                    episode.overview ?? L10n.noOverviewAvailable
                }
            }

            var body: some View {
                VStack(alignment: .leading) {
                    Button {
                        router.route(
                            to: .videoPlayer(
                                item: episode,
                                queue: EpisodeMediaPlayerQueue(episode: episode)
                            )
                        )
                    } label: {
                        ImageView(episode.imageSource(.primary, maxWidth: UIDevice.isTV ? 500 : 250))
                            .failure {
                                SystemImageContentView(systemName: episode.systemImage)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay {
                                overlayView
                            }
                            .contentShape(.contextMenuPreview, Rectangle())
                            .backport
                            .matchedTransitionSource(id: "item", in: namespace)
                            .posterStyle(.landscape)
                            .posterShadow()
                    }
                    #if os(tvOS)
                    .buttonStyle(.card)
                    #endif

                    EpisodeContent(
                        header: episode.displayTitle,
                        subHeader: episode.episodeLocator ?? .emptyDash,
                        content: episodeContent
                    ) {
                        router.route(to: .item(item: episode), in: namespace)
                    }
                }
            }
        }

        private struct EpisodeContent: View {

            let header: String
            let subHeader: String
            let content: String
            let onSelect: () -> Void

            var body: some View {
                Button(action: onSelect) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subHeader)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Text(header)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Text(content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(UIDevice.isTV ? 3 : 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
