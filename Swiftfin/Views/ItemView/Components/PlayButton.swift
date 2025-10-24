//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct PlayButton: View {

        @Default(.accentColor)
        private var accentColor

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        private let logger = Logger.swiftfin()

        private var isEnabled: Bool {
            viewModel.selectedMediaSource != nil
        }

        private var title: String {
            /// Use the Season/Episode label for the Series ItemView
            if let seriesViewModel = viewModel as? SeriesItemViewModel,
               let seasonEpisodeLabel = seriesViewModel.playButtonItem?.seasonEpisodeLabel
            {
                return seasonEpisodeLabel

                /// Use a Play/Resume label for single Media Source items that are not Series
            } else if let playButtonLabel = viewModel.playButtonItem?.playButtonLabel {
                return playButtonLabel

                /// Fallback to a generic `Play` label
            } else {
                return L10n.play
            }
        }

        private var source: String? {
            guard let sourceLabel = viewModel.selectedMediaSource?.displayTitle,
                  viewModel.item.mediaSources?.count ?? 0 > 1
            else {
                return nil
            }

            return sourceLabel
        }

        var body: some View {
            Button {
                play()
            } label: {
                HStack {
                    Label(title, systemImage: "play.fill")
                        .font(.callout)
                        .fontWeight(.semibold)

                    if let source {
                        Marquee(source, speed: 40, delay: 3, fade: 5)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: 175)
                    }
                }
                .padding(.horizontal, 5)
            }
            .buttonStyle(.tintedMaterial(tint: accentColor, foregroundColor: accentColor.overlayColor))
            .isSelected(true)
            .contextMenu {
                if viewModel.playButtonItem?.userData?.playbackPositionTicks != 0 {
                    Button(L10n.playFromBeginning, systemImage: "gobackward") {
                        play(fromBeginning: true)
                    }
                }

                if viewModel.item.canShuffle {
                    Button(L10n.shuffle, systemImage: "shuffle") {
                        viewModel.playShuffle(router: router.router)
                    }
                }
            }
            .disabled(!isEnabled)
        }

        private func play(fromBeginning: Bool = false) {
            guard let playButtonItem = viewModel.playButtonItem,
                  let selectedMediaSource = viewModel.selectedMediaSource
            else {
                logger.error("Play selected with no item or media source")
                return
            }

            let queue: (any MediaPlayerQueue)? = {
                if playButtonItem.type == .episode {
                    return EpisodeMediaPlayerQueue(episode: playButtonItem)
                }
                return nil
            }()

            let provider = MediaPlayerItemProvider(item: playButtonItem) { item in
                try await MediaPlayerItem.build(
                    for: item,
                    mediaSource: selectedMediaSource
                ) {
                    if fromBeginning {
                        $0.userData?.playbackPositionTicks = 0
                    }
                }
            }

            router.route(
                to: .videoPlayer(
                    provider: provider,
                    queue: queue
                )
            )
        }
    }
}
