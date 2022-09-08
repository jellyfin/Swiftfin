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
        @FocusState
        var isFocused: Bool

        var body: some View {
            Button {
                if let selectedVideoPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    itemRouter.route(to: \.videoPlayer, selectedVideoPlayerViewModel)
                } else {
                    LogManager.log.error("Attempted to play item but no playback information available")
                }
            } label: {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.black)
                        .font(.title3)
                    Text(viewModel.playButtonText())
                        .foregroundColor(viewModel.playButtonItem == nil ? Color(UIColor.secondaryLabel) : Color.black)
                        .fontWeight(.semibold)
                }
                .frame(width: 400, height: 100)
                .background {
                    if isFocused {
                        viewModel.playButtonItem == nil ? Color.secondarySystemFill : Color.white
                    } else {
                        Color.white
                            .opacity(0.5)
                    }
                }
                .cornerRadius(10)
            }
            .focused($isFocused)
            .buttonStyle(.card)
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

                    Button(role: .cancel) {} label: {
                        L10n.cancel.text
                    }
                }
            }
        }
    }
}
