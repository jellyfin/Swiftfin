//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeCard: View {

        @Default(.accentColor)
        private var accentColor

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
            } else if episode.userData?.isPlayed ?? false {
                WatchedIndicator(size: 25)
            } else if episode.canBePlayed && !episode.isLiveStream {
                UnwatchedIndicator(size: 25)
                    .foregroundColor(accentColor)
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
                    ImageView(episode.imageSource(.primary, maxWidth: 250))
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

                SeriesEpisodeSelector.EpisodeContent(
                    header: episode.displayTitle,
                    subHeader: episode.episodeLocator ?? .emptyDash,
                    content: episodeContent
                ) {
                    router.route(to: .item(item: episode), in: namespace)
                }
            }
        }
    }
}
