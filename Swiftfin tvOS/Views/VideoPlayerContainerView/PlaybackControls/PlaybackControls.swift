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

        @OnPressEvent
        private var onPressEvent

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
                VStack(spacing: 0) {
                    NavigationBar()
                        .focusSection()
                        .isVisible(isPresentingOverlay)
                        .padding(.horizontal)

                    PlaybackProgress()
                        .focusSection()
                        .isVisible(isPresentingOverlay || isScrubbing)
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
                }
            }
        }

        var body: some View {
            ZStack {
                bottomContent
                    .frame(maxHeight: .infinity, alignment: .bottom)
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
                    .animation(.linear(duration: 0.1), value: isScrubbing)
                    .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
                    .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)

                if manager.playbackRequestStatus == .paused {
                    Label(L10n.pause, systemImage: "pause.fill")
                        .transition(.opacity.combined(with: .scale).animation(.bouncy(duration: 0.7, extraBounce: 0.2)))
                        .font(.system(size: 72, weight: .bold, design: .default))
                        .labelStyle(.iconOnly)
                        .frame(maxHeight: .infinity)
                }
            }
            .onFirstAppear {
                containerState.isPresentingOverlay = true
            }
            .onReceive(onPressEvent) { press in
                handlePressEvent(press)
            }
        }

        private func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

            /// Global Rule:
            /// - Any remote button press should show the overlay if hidden
            if !isPresentingOverlay {
                if press.type == .playPause {
                    switch manager.playbackRequestStatus {
                    case .playing:
                        manager.setPlaybackRequestStatus(status: .paused)
                    case .paused:
                        manager.setPlaybackRequestStatus(status: .playing)
                    }
                }
                containerState.isPresentingOverlay = true
                press.resolve(.handled)
                return
            }

            /// Overlay Rules
            switch (press.type, press.phase) {

            /// Use Arrow Keys Normally
            case (.playPause, _):
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                containerState.timer.poke()
                press.resolve(.handled)

            /// Use Menu Key to Open the Overlay or Close the Player
            case (.menu, _):
                if isPresentingSupplement {
                    containerState.selectedSupplement = nil
                    containerState.timer.poke()
                    press.resolve(.handled)

                } else {
                    containerState.isPresentingOverlay = false
                    manager.proxy?.stop()
                    router.dismiss()
                    press.resolve(.handled)
                }

            /// Use Default Key Press Actions
            default:
                containerState.timer.poke()
                press.resolve(.fallback)
            }
        }
    }
}
