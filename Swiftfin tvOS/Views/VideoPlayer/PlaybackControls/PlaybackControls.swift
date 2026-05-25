//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct PlaybackControls: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        var jumpForwardInterval

        @EnvironmentObject
        var containerState: VideoPlayerContainerState
        @EnvironmentObject
        var manager: MediaPlayerManager

        @Toaster
        var toaster: ToastProxy

        @FocusState
        private var isPlaybackProgressFocused: Bool

        @State
        var speedBoostTimer: Timer?
        @State
        var isSpeedBoosting: Bool = false
        @State
        var pendingJumpWork: DispatchWorkItem?

        var body: some View {
            VStack(spacing: 30) {

                NavigationBar()
                    .isVisible(
                        containerState.isPresentingOverlay &&
                            !containerState.isScrubbing &&
                            !containerState.isPresentingSupplement
                    )
                    .disabled(containerState.isPresentingSupplement)

                PlaybackProgress()
                    .focused($isPlaybackProgressFocused, equals: true)
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(
                        (containerState.isPresentingOverlay || containerState.isScrubbing) &&
                            !containerState.isPresentingSupplement
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .edgePadding(.horizontal)
            .animation(.easeInOut(duration: 0.25), value: containerState.isPresentingSupplement)
            .animation(.easeInOut(duration: 0.25), value: containerState.isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: containerState.isScrubbing)
            .alert(L10n.closePlayer, isPresented: $containerState.isPresentingCloseConfirmation) {
                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.ok, role: .destructive) {
                    manager.stop()
                }
            } message: {
                Text(L10n.closePlayerWarning)
            }
            .onFirstAppear {
                containerState.isPresentingOverlay = true
                isPlaybackProgressFocused = true
            }
            .onChange(of: containerState.isPresentingOverlay) { _, newValue in
                if newValue {
                    isPlaybackProgressFocused = true
                }
            }
            .onChange(of: manager.playbackRequestStatus) { _, newValue in
                if newValue == .paused, !containerState.isPresentingOverlay {
                    containerState.isPresentingOverlay = true
                }
            }
            .onReceive(containerState.containerView?.onPressEvent ?? .init()) { press in
                handlePressEvent(press)
            }
            .onChange(of: containerState.isProgressBarFocused) { _, newValue in
                if !newValue {
                    containerState.cancelScrub()

                    if isSpeedBoosting {
                        stopSpeedBoost()
                    }
                }
            }
        }
    }
}
