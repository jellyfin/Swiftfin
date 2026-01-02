//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeCard: View {

        @Namespace
        private var namespace

        @Router
        private var router

        let episode: BaseItemDto

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
                        .contentShape(.contextMenuPreview, Rectangle())
                        .posterStyle(.landscape)
                        .backport
                        .matchedTransitionSource(id: "item", in: namespace)
                        .posterShadow()
                }
                .foregroundStyle(.primary, .secondary)

                SeriesEpisodeSelector.EpisodeContent(
                    title: episode.displayTitle,
                    subtitle: episode.episodeLocator ?? .emptyDash,
                    description: episodeContent
                ) {
                    router.route(to: .item(item: episode), in: namespace)
                }
            }
        }
    }
}
