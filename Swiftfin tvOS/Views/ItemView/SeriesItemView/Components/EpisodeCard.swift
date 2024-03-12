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

// TODO: Should episodes also respect some indicator settings?

struct EpisodeCard: View {

    @Injected(LogManager.service)
    private var logger

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
            Button {
                router.route(to: \.item, episode)
            } label: {
                VStack(alignment: .leading) {

                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: 0.01)
                            .frame(maxWidth: .infinity)

                        Text(episode.episodeLocator ?? L10n.unknown)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(episode.displayTitle)
                        .font(.footnote)
                        .padding(.bottom, 1)

                    if episode.isUnaired {
                        Text(episode.airDateLabel ?? L10n.noOverviewAvailable)
                            .font(.caption)
                            .lineLimit(1)
                    } else {
                        Text(episode.overview ?? L10n.noOverviewAvailable)
                            .font(.caption)
                            .lineLimit(3)
                    }

                    Spacer(minLength: 0)

                    L10n.seeMore.text
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.jellyfinPurple)
                }
                .aspectRatio(510 / 220, contentMode: .fill)
                .padding()
            }
            .buttonStyle(.card)
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
            guard let mediaSource = episode.mediaSources?.first else {
                logger.error("No media source attached to episode", metadata: ["episode title": .string(episode.displayTitle)])
                return
            }
            router.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: episode, mediaSource: mediaSource))
        }
    }
}
