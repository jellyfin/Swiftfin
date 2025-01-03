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

        @EnvironmentObject
        private var mainRouter: MainCoordinator.Router

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
                if let playButtonItem = viewModel.playButtonItem, let selectedMediaSource = viewModel.selectedMediaSource {
                    mainRouter.route(to: \.videoPlayer, OnlineVideoPlayerManager(item: playButtonItem, mediaSource: selectedMediaSource))
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
//            .contextMenu {
//                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
//                    Button {
//                        if let selectedVideoPlayerViewModel = viewModel.legacyselectedVideoPlayerViewModel {
//                            selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
//                            router.route(to: \.legacyVideoPlayer, selectedVideoPlayerViewModel)
//                        } else {
//                            logger.error("Attempted to play item but no playback information available")
//                        }
//                    } label: {
//                        Label(L10n.playFromBeginning, systemImage: "gobackward")
//                    }
//                }
//            }
        }
    }
}
