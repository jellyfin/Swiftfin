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

        // MARK: - Validation

        private var isEnabled: Bool {
            viewModel.selectedMediaSource != nil
        }

        // MARK: - Title

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

        // MARK: - Media Source

        private var source: String? {
            guard let sourceLabel = viewModel.selectedMediaSource?.displayTitle,
                  viewModel.item.mediaSources?.count ?? 0 > 1
            else {
                return nil
            }

            return sourceLabel
        }

        // MARK: - Body

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
            }
            .disabled(!isEnabled)
        }

        // MARK: - Play Content

        private func play(fromBeginning: Bool = false) {
            guard var playButtonItem = viewModel.playButtonItem,
                  let selectedMediaSource = viewModel.selectedMediaSource
            else {
                logger.error("Play selected with no item or media source")
                return
            }

            if fromBeginning {
                playButtonItem.userData?.playbackPositionTicks = 0
            }

            router.route(
                to: .videoPlayer(
                    manager: OnlineVideoPlayerManager(
                        item: playButtonItem,
                        mediaSource: selectedMediaSource
                    )
                )
            )
        }
    }
}
