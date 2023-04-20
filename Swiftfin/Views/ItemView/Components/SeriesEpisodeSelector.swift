//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SeriesEpisodeSelector: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @ObservedObject
    var viewModel: SeriesItemViewModel

    var body: some View {
        MenuPosterHStack(
            type: .landscape,
            manager: viewModel,
            singleImage: true
        )
        .scaleItems(1.2)
        .imageOverlay { type in
            EpisodeOverlay(type: type)
        }
        .content { type in
            EpisodeContent(type: type)
        }
        .onSelect { item in
            guard let mediaSource = item.mediaSources?.first else { return }
            mainRouter.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: item, mediaSource: mediaSource))
        }
    }
}

extension SeriesEpisodeSelector {

    struct EpisodeOverlay: View {

        let type: PosterButtonType<BaseItemDto>

        var body: some View {
            if case let PosterButtonType.item(episode) = type {
                if let progressLabel = episode.progressLabel {
                    LandscapePosterProgressBar(
                        title: progressLabel,
                        progress: (episode.userData?.playedPercentage ?? 0) / 100
                    )
                } else if episode.userData?.isPlayed ?? false {
                    ZStack(alignment: .bottomTrailing) {
                        Color.clear

                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30, alignment: .bottomTrailing)
                            .accentSymbolRendering(accentColor: .white)
                            .padding()
                    }
                }
            } else {
                EmptyView()
            }
        }
    }

    struct EpisodeContent: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        @ScaledMetric
        private var staticOverviewHeight: CGFloat = 50

        let type: PosterButtonType<BaseItemDto>

        @ViewBuilder
        private var subHeader: some View {
            Group {
                switch type {
                case .loading:
                    String(repeating: "a", count: 5).text
                        .redacted(reason: .placeholder)
                case .noResult:
                    String.emptyDash.text
                case let .item(episode):
                    Text(episode.episodeLocator ?? L10n.unknown)
                }
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }

        @ViewBuilder
        private var header: some View {
            Group {
                switch type {
                case .loading:
                    String(repeating: "a", count: Int.random(in: 8 ..< 18)).text
                        .redacted(reason: .placeholder)
                case .noResult:
                    L10n.noResults.text
                case let .item(episode):
                    Text(episode.displayTitle)
                }
            }
            .font(.body)
            .foregroundColor(.primary)
            .padding(.bottom, 1)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }

        @ViewBuilder
        private var content: some View {
            Group {
                switch type {
                case .loading:
                    String(repeating: "a", count: Int.random(in: 50 ..< 100)).text
                        .redacted(reason: .placeholder)
                case .noResult:
                    L10n.noOverviewAvailable.text
                case let .item(episode):
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .frame(height: staticOverviewHeight)

                        if episode.isUnaired {
                            Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                        } else {
                            Text(episode.overview ?? L10n.noOverviewAvailable)
                        }
                    }

                    L10n.seeMore.text
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(accentColor)
                }
            }
            .font(.caption.weight(.light))
            .foregroundColor(.secondary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
        }

        var body: some View {
            Button {
                if case let PosterButtonType.item(item) = type {
                    router.route(to: \.item, item)
                }
            } label: {
                VStack(alignment: .leading) {
                    subHeader

                    header

                    content
                }
            }
        }
    }
}
