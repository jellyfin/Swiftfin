//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct PlaybackControls: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var focusGuide: FocusGuide
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @Router
        private var router

        @State
        private var contentSize: CGSize = .zero
        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        @ViewBuilder
        private var bottomContent: some View {
            if !isPresentingSupplement {

                NavigationBar()
                    .focusGuide(
                        focusGuide,
                        tag: "navigationBar",
                        bottom: "playbackProgress"
                    )
                    .padding(.vertical, .none)

                PlaybackProgress()
                    .focusGuide(
                        focusGuide,
                        tag: "playbackProgress",
                        top: "navigationBar",
                        bottom: "supplementButtons"
                    )
                    .frame(height: 100)
                    .onMoveCommand { direction in
                        switch direction {
                        case .left:
                            manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
                        case .right:
                            manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
                        default:
                            break
                        }
                    }
                // .isVisible(isScrubbing || isPresentingOverlay)
            }
        }

        var body: some View {
            VStack {
                Spacer()

                bottomContent
                    .edgePadding()
                    .background(alignment: .bottom) {
                        Color.black
                            .maskLinearGradient {
                                (location: 0, opacity: 0)
                                (location: 1, opacity: 0.5)
                            }
                            .isVisible(isScrubbing || isPresentingOverlay)
                            .animation(.linear(duration: 0.25), value: isPresentingOverlay)
                    }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
            .onChange(of: containerState.isPresentingOverlay) { _, newValue in
                if newValue && focusGuide.focusedTag != "playbackProgress" {
                    focusGuide.transition(to: "playbackProgress")
                } else {
                    focusGuide.transition(to: nil)
                }
            }
            .onPlayPauseCommand {
                manager.togglePlayPause()
            }
            .onExitCommand {
                if isPresentingSupplement {
                    containerState.selectedSupplement = nil
                } else {
                    manager.proxy?.stop()
                    router.dismiss()
                }
            }
        }
    }
}
