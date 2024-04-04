//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeCard: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let episode: BaseItemDto

        var body: some View {
            PosterButton(
                item: episode,
                type: .landscape,
                singleImage: true
            )
            .content {
                let content: String = if episode.isUnaired {
                    episode.airDateLabel ?? L10n.noOverviewAvailable
                } else {
                    episode.overview ?? L10n.noOverviewAvailable
                }

                SeriesEpisodeSelector.EpisodeContent(
                    subHeader: episode.episodeLocator ?? .emptyDash,
                    header: episode.displayTitle,
                    content: content
                )
                .onSelect {
                    router.route(to: \.item, episode)
                }
            }
            .imageOverlay {
                ZStack {
                    if episode.userData?.isPlayed ?? false {
                        WatchedIndicator(size: 45)
                    } else {
                        if (episode.userData?.playbackPositionTicks ?? 0) > 0 {
                            LandscapePosterProgressBar(
                                title: episode.progressLabel ?? L10n.continue,
                                progress: (episode.userData?.playedPercentage ?? 0) / 100
                            )
                            .padding()
                        }
                    }
                }
            }
            .onSelect {
                guard let mediaSource = episode.mediaSources?.first else { return }
                router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: episode, mediaSource: mediaSource))
            }
        }
    }
}
