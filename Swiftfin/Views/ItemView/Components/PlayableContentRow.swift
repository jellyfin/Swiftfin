//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct PlayableContentRow: View {

        @Default(.accentColor)
        private var accentColor

        private let logger = Logging.Logger.swiftfin()

        @Router
        private var router

        let item: BaseItemDto
        let onSelect: () -> Void

        var body: some View {
            ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                if item.type == .audio {
                    ZStack {
                        Color.clear

                        ImageView(item.squareImageSources(maxWidth: 60))
                            .failure {
                                SystemImageContentView(systemName: item.systemImage)
                            }

                        overlayView
                    }
                    .squarePosterStyle()
                    .frame(width: 60, height: 60)
                } else {
                    ZStack {
                        Color.clear

                        ImageView(item.portraitImageSources(maxWidth: 60))
                            .failure {
                                SystemImageContentView(systemName: item.systemImage)
                            }

                        overlayView
                    }
                    .posterStyle(.portrait)
                    .frame(width: 60, height: 90)
                }
            } content: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let parent = item.parentTitle {
                            Text(parent)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Text(item.displayTitle)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else if let premiereDateYear = item.premiereDateYear {
                            Text(premiereDateYear)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // TODO: Make Ornament
                    Button(L10n.play, systemImage: "play.fill") {
                        if let itemMediaSource = item.mediaSources?.first {
                            router.route(
                                to: .videoPlayer(
                                    manager: OnlineVideoPlayerManager(
                                        item: item,
                                        mediaSource: itemMediaSource
                                    )
                                )
                            )
                        } else {
                            logger.error("No media source available")
                        }
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(accentColor)
                }
            }
            .onSelect(perform: onSelect)
        }

        @ViewBuilder
        private var overlayView: some View {
            ZStack {
                if item.userData?.isPlayed ?? false {
                    WatchedIndicator(size: 25)
                } else {
                    if (item.userData?.playbackPositionTicks ?? 0) > 0 {
                        ProgressIndicator(progress: (item.userData?.playedPercentage ?? 0) / 100, height: 5)
                    }
                }
            }
        }
    }
}
