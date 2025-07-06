//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Logging
import SwiftUI

// TODO: fix play from beginning

extension ItemView {

    struct PlayButton: View {

        @Default(.accentColor)
        private var accentColor

        private let logger = Logger.swiftfin()

        @Injected(\.downloadManager)
        private var downloadManager

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
                if let downloadTask = downloadManager.task(for: viewModel.item),
                   case .complete = downloadTask.state
                {
                    logger.info("Playing downloaded content for item: \(viewModel.item.displayTitle)")
                    router.route(
                        to: .videoPlayer(
                            manager: DownloadVideoPlayerManager(downloadTask: downloadTask)
                        )
                    )
                } else if let playButtonItem = viewModel.playButtonItem,
                          let selectedMediaSource = viewModel.selectedMediaSource
                {
                    logger.info("Playing online content for item: \(viewModel.item.displayTitle)")
                    router.route(
                        to: .videoPlayer(
                            manager: OnlineVideoPlayerManager(
                                item: playButtonItem,
                                mediaSource: selectedMediaSource
                            )
                        )
                    )
                } else {
                    logger.error("No media source available for item: \(viewModel.item.displayTitle)")
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

                        // Show offline indicator if downloaded
                        if let downloadTask = downloadManager.task(for: viewModel.item),
                           case .complete = downloadTask.state
                        {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(accentColor.overlayColor.opacity(0.8))
                        }
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
