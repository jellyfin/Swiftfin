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

        @FocusState
        private var isFocused: Bool

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
            HStack(spacing: 20) {
                playButton

                if multipleVersions {
                    VersionMenu(viewModel: viewModel, mediaSources: mediaSources)
                        .frame(width: 100, height: 100)
                }
            }
        }

        // MARK: - Play Button

        private var playButton: some View {
            Button {
                play()
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                        .font(.title3)

                    // TODO: Use `MarqueeText`
                    Text(title)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isEnabled ? .black : Color(UIColor.secondaryLabel))
                .padding(20)
                .frame(width: multipleVersions ? 320 : 440, height: 100, alignment: .center)
                .background {
                    if isFocused {
                        isEnabled ? Color.white : Color.secondarySystemFill
                    } else {
                        Color.white
                            .opacity(0.5)
                    }
                }
                .cornerRadius(10)
            }
            .buttonStyle(.card)
            .contextMenu {
                if viewModel.playButtonItem?.userData?.playbackPositionTicks != 0 {
                    Button(L10n.playFromBeginning, systemImage: "gobackward") {
                        play(fromBeginning: true)
                    }
                }
            }
            .disabled(!isEnabled)
            .focused($isFocused)
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
