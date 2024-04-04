//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeCard: View {

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router
        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let episode: BaseItemDto

        @ViewBuilder
        private var overlayView: some View {
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
                        .paletteOverlayRendering(color: .white)
                        .padding()
                }
            }
        }

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
                overlayView
            }
            .onSelect {
                guard let mediaSource = episode.mediaSources?.first else { return }
                mainRouter.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: episode, mediaSource: mediaSource))
            }
        }
    }
}
