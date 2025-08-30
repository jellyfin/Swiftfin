//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: error state

extension VideoPlayer {

    struct PlaybackControls: View {

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var bottomContentFrame: CGRect = .zero

        // TODO: move to containerState
        @State
        private var isGestureLocked: Bool = false

        // TODO: move to containerstate
        @StateObject
        private var jumpProgressObserver: JumpProgressObserver = .init()

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        // MARK: body

        var body: some View {
            ZStack {

                // MARK: - Buttons and Supplements

                VStack {
                    NavigationBar()
                        .frame(height: 50)
                        .isVisible(!isScrubbing && isPresentingOverlay)
                        .padding(.top, safeAreaInsets.top)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .offset(y: isPresentingOverlay ? 0 : -20)

                    Spacer()
                        .allowsHitTesting(false)

                    // TODO: finalize design/placement
//                    if manager.proxy?.isBuffering.value == true {
//                        ProgressView()
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .frame(height: 30)
//                            .padding(.leading, safeAreaInsets.leading)
//                    }

                    PlaybackProgress()
                        .isVisible(isPresentingOverlay && !isPresentingSupplement)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .padding(.bottom, 10)
                        .trackingFrame($bottomContentFrame)
                        .background {
                            if isPresentingOverlay && !isPresentingSupplement {
                                EmptyHitTestView()
                            }
                        }
                        .background(alignment: .top) {
                            Color.black
                                .maskLinearGradient {
                                    (location: 0, opacity: 0)
                                    (location: 1, opacity: 0.3)
                                }
                                .isVisible(isScrubbing)
                                .frame(height: bottomContentFrame.height + 50 + EdgeInsets.edgePadding)
                        }
                }

                // TODO: offset by supplement container height
                PlaybackButtons()
                    .isVisible(!isScrubbing && containerState.isPresentingPlaybackControls)
            }
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: containerState.isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: containerState.isPresentingOverlay)
            .environmentObject(jumpProgressObserver)
        }
    }
}
