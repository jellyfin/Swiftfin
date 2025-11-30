//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeCard: View {

        @Router
        private var router

        let episode: BaseItemDto

        @FocusState
        private var isFocused: Bool

        @ViewBuilder
        private var overlayView: some View {
            ZStack {
                if let progress = episode.progress {
                    PosterProgressBar(
                        title: "Test",
                        progress: progress,
                        posterDisplayType: .landscape
                    )
                } else if episode.userData?.isPlayed == true {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black)
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .bottomTrailing
                        )
                }

                if isFocused {
                    Image(systemName: "play.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.secondary)
                }
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
                    ZStack {
                        Color.clear

                        ImageView(episode.imageSource(.primary, maxWidth: 500))
                            .failure {
                                SystemImageContentView(systemName: episode.systemImage)
                            }

                        overlayView
                    }
                    .posterStyle(.landscape)
                }
                .buttonStyle(.card)
                .posterShadow()
                .focused($isFocused)

                SeriesEpisodeSelector.EpisodeContent(
                    subHeader: episode.episodeLocator ?? .emptyDash,
                    header: episode.displayTitle,
                    content: episodeContent
                )
                .onSelect {
                    router.route(to: .item(item: episode))
                }
            }
        }
    }
}
