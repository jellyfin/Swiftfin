//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

// TODO: fix play from beginning

extension ItemView {

    struct PlayButton: View {

        @Default(.accentColor)
        private var accentColor

        @Injected(\.logService)
        private var logger

        @Router
        private var router

        @ObservedObject
        var viewModel: ItemViewModel

        private var title: String {
            if let seriesViewModel = viewModel as? SeriesItemViewModel {
                return seriesViewModel.playButtonItem?.seasonEpisodeLabel ?? L10n.play
            } else {
                return viewModel.playButtonItem?.playButtonLabel ?? L10n.play
            }
        }

        var body: some View {
            Button {
                if let playButtonItem = viewModel.playButtonItem,
                   let selectedMediaSource = viewModel.selectedMediaSource
                {
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
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : accentColor)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))

                        Text(title)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : accentColor.overlayColor)
                }
            }
            .disabled(viewModel.playButtonItem == nil)
            .contextMenu {
                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                    Button {
                        if var playButtonItem = viewModel.playButtonItem,
                           let selectedMediaSource = viewModel.selectedMediaSource
                        {
                            /// Reset playback to the beginning
                            playButtonItem.userData?.playbackPositionTicks = 0

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
                        }
                    } label: {
                        Label(L10n.playFromBeginning, systemImage: "gobackward")
                    }
                }
            }
        }
    }
}
