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

        // MARK: - Error State

        @State
        private var error: Error?

        // MARK: - ddd

        private var isValid: Bool {
            viewModel.playButtonItem != nil
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
                playContent()
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(!isValid ? Color(UIColor.secondarySystemFill) : accentColor)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))

                        // TODO: Use `MarqueeText`
                        Text(title)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(!isValid ? Color(UIColor.secondaryLabel) : accentColor.overlayColor)
                }
            }
            .disabled(!isValid)
            .contextMenu {
                if viewModel.playButtonItem?.userData?.playbackPositionTicks ?? 0 > 0 {
                    Button(L10n.playFromBeginning, systemImage: "gobackward") {
                        playContent(restart: true)
                    }
                }
            }
            .errorMessage($error)
        }

        // MARK: - Play Content

        private func playContent(restart: Bool = false) {
            if var playButtonItem = viewModel.playButtonItem,
               let selectedMediaSource = viewModel.selectedMediaSource
            {
                if restart {
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
            } else {
                logger.error("No media source available")
                error = JellyfinAPIError("No media source available")
            }
        }
    }
}
