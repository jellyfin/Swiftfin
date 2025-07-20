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

        // MARK: - ddd

        private var isEnabled: Bool {
            viewModel.selectedMediaSource != nil
        }

        // MARK: - Title

        private var title: String {
            if let seriesViewModel = viewModel as? SeriesItemViewModel,
               let seasonEpisodeLabel = seriesViewModel.playButtonItem?.seasonEpisodeLabel
            {
                return seasonEpisodeLabel
            } else if let playButtonLabel = viewModel.playButtonItem?.playButtonLabel {
                return playButtonLabel
            } else {
                return L10n.play
            }

            // TODO: For use with `MarqueeText` on the `PlayButton`

            /* if let sourceLabel = viewModel.selectedMediaSource?.displayTitle,
                viewModel.item.mediaSources?.count ?? 0 > 1
             {
                 return sourceLabel
             } else if let seriesViewModel = viewModel as? SeriesItemViewModel,
                       let seasonEpisodeLabel = seriesViewModel.playButtonItem?.seasonEpisodeLabel
             {
                 return seasonEpisodeLabel
             } else if let playButtonLabel = viewModel.playButtonItem?.playButtonLabel {
                 return playButtonLabel
             } else {
                 return L10n.play
             } */
        }

        // MARK: - Body

        var body: some View {
            Button {
                play()
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundStyle(isEnabled ? accentColor : Color.secondarySystemFill)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))

                        // TODO: Use `MarqueeText`
                        Text(title)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(isEnabled ? accentColor.overlayColor : Color(UIColor.secondaryLabel))
                }
            }
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
