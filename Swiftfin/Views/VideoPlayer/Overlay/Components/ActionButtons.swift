//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct ActionButtons: View {

        @Default(.VideoPlayer.autoPlay)
        private var autoPlay
        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled
        @Default(.VideoPlayer.playNextItem)
        private var playNextItem
        @Default(.VideoPlayer.playPreviousItem)
        private var playPreviousItem

        @Environment(\.aspectFilled)
        @Binding
        private var aspectFilled: Bool

        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        // TODO: Break up into individual buttons
        @ViewBuilder
        private var barButtons: some View {
            HStack(spacing: 0) {

                if viewModel.item.type == .episode {

                    if playPreviousItem {
                        Button {
                            videoPlayerManager.selectPreviousViewModel()
                        } label: {
                            Image(systemName: "chevron.left.circle")
                                .frame(width: 50, height: 50)
                        }
                        .disabled(videoPlayerManager.previousViewModel == nil)
                        .foregroundColor(videoPlayerManager.previousViewModel == nil ? .gray : .white)
                    }

                    if playNextItem {
                        Button {
                            videoPlayerManager.selectNextViewModel()
                        } label: {
                            Image(systemName: "chevron.right.circle")
                                .frame(width: 50, height: 50)
                        }
                        .disabled(videoPlayerManager.nextViewModel == nil)
                        .foregroundColor(videoPlayerManager.nextViewModel == nil ? .gray : .white)
                    }

                    if autoPlay {
                        Button {
                            autoPlayEnabled.toggle()
                        } label: {
                            Group {
                                if autoPlayEnabled {
                                    Image(systemName: "play.circle.fill")
                                } else {
                                    Image(systemName: "stop.circle")
                                }
                            }
                            .frame(width: 50, height: 50)
                        }
                    }
                }

                Button {
                    if aspectFilled {
                        aspectFilled = false
                        UIView.animate(withDuration: 0.2) {
                            videoPlayerProxy.aspectFill(0)
                        }
                    } else {
                        aspectFilled = true
                        UIView.animate(withDuration: 0.2) {
                            videoPlayerProxy.aspectFill(1)
                        }
                    }
                } label: {
                    Group {
                        if aspectFilled {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                        } else {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                        }
                    }
                    .frame(width: 50, height: 50)
                }
            }
        }

        var body: some View {
            HStack(spacing: 0) {
                barButtons

                OverlayMenu()
            }
        }
    }
}
