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

        // MARK: - Dialog States

        @State
        private var isPresentingResume = false

        @State
        private var error: Error?

        // MARK: - Media Sources

        private var mediaSources: [MediaSourceInfo] {
            viewModel.playButtonItem?.mediaSources ?? []
        }

        // MARK: - Multiple Media Sources

        private var multipleVersions: Bool {
            mediaSources.count > 1
        }

        // MARK: - Validation

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

        // MARK: - Resume Alert Details

        private var alertTitle: String {
            if viewModel.playButtonItem?.type == .episode {
                return viewModel.playButtonItem?.seriesName ?? L10n.playback
            } else {
                return viewModel.playButtonItem?.displayTitle ?? L10n.playback
            }
        }

        private var alertDescription: String? {
            if viewModel.playButtonItem?.type == .episode {
                return viewModel.playButtonItem?.displayTitle
            } else {
                return nil
            }
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
                if viewModel.playButtonItem?.userData?.playbackPositionTicks == 0 {
                    playContent()
                } else {
                    isPresentingResume = true
                }
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                        .foregroundColor(!isValid ? Color(UIColor.secondaryLabel) : Color.black)
                        .font(.title3)

                    Text(title)
                        .foregroundStyle(!isValid ? Color(UIColor.secondaryLabel) : Color.black)
                        .fontWeight(.semibold)
                }
                .padding(20)
                .frame(width: multipleVersions ? 320 : 440, height: 100, alignment: .center)
                .background {
                    if isFocused {
                        !isValid ? Color.secondarySystemFill : Color.white
                    } else {
                        Color.white
                            .opacity(0.5)
                    }
                }
                .cornerRadius(10)
            }
            .disabled(!isValid)
            .focused($isFocused)
            .buttonStyle(.card)
            .alert(alertTitle, isPresented: $isPresentingResume) {
                Button(L10n.resume) {
                    playContent()
                }

                Button(L10n.playFromBeginning) {
                    playContent(restart: true)
                }

                Button(L10n.cancel, role: .cancel) {
                    isPresentingResume = false
                }
            } message: {
                if let alertDescription {
                    Text(alertDescription)
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
