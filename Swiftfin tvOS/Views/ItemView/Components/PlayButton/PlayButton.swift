//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Logging
import SwiftUI

extension ItemView {

    struct PlayButton: View {

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        private let logger = Logger.swiftfin()

        // MARK: - Media Sources

        private var mediaSources: [MediaSourceInfo] {
            viewModel.playButtonItem?.mediaSources ?? []
        }

        // MARK: - Multiple Media Sources

        private var multipleVersions: Bool {
            mediaSources.count > 1
        }

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
            HStack(spacing: 30) {
                playButton

                if multipleVersions {
                    VersionMenu(viewModel: viewModel, mediaSources: mediaSources)
                        .frame(width: 100, height: 100)
                }
            }
            .fontWeight(.semibold)
        }

        // MARK: - Play Button

        private var playButton: some View {
            Button {
                play()
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")

                    VStack {
                        Text(title)

                        if let source {
                            Marquee(source, animateWhenFocused: true)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(
                .tintedMaterial(
                    tint: .white,
                    foregroundColor: .black
                )
            )
            .contextMenu {
                if viewModel.playButtonItem?.userData?.playbackPositionTicks != 0 {
                    Button(L10n.playFromBeginning, systemImage: "gobackward") {
                        play(fromBeginning: true)
                    }
                }
            }
            .isSelected(true)
            .enabled(isEnabled)
        }

        // MARK: - Play Content

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
