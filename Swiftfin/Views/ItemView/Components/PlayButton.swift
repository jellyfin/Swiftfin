//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct PlayButton: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            Button {
                if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                } else {
                    LogManager.log.error("Attempted to play item but no playback information available")
                }
            } label: {
                ZStack {
                    Rectangle()
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondarySystemFill) : Color.jellyfinPurple)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                        Text(viewModel.playButtonText())
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.white)
                }
            }
            .contextMenu {
                if viewModel.playButtonItem != nil, viewModel.item.userData?.playbackPositionTicks ?? 0 > 0 {
                    Button {
                        if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                            selectedVideoPlayerViewModel.injectCustomValues(startFromBeginning: true)
                            itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                        } else {
                            LogManager.log.error("Attempted to play item but no playback information available")
                        }
                    } label: {
                        Label(L10n.playFromBeginning, systemImage: "gobackward")
                    }
                }
            }
        }
    }
}
