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

        typealias ViewState = VideoPlayer.ViewState

        @Default(.VideoPlayer.jumpBackwardInterval)
        var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        var jumpForwardInterval

        @Environment(ViewState.self)
        var viewState
        @EnvironmentObject
        var manager: MediaPlayerManager

        @EnvironmentObject
        private var focusCoordinator: FocusCoordinator

        @State
        var seekingPress: UIPress.PressType?
        @State
        var speedBoostTimer: Timer?
        @State
        var isSpeedBoosting: Bool = false
        @State
        var pendingJumpWork: DispatchWorkItem?

        @Toaster
        var toaster: ToastProxy

        var body: some View {
            @Bindable
            var viewState = viewState

            VStack(spacing: 30) {

                Toolbar()
                    .isVisible(viewState.visibleElements.contains(.toolbar))
                    .enabled(viewState.visibleElements.contains(.toolbar))

                PlaybackProgress()
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(viewState.isPresentingProgress)
                    .enabled(viewState.isPresentingProgress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .edgePadding(.horizontal)
            .focusSection()
            .coordinatedFocus(ViewState.Focus.controls)
            .animation(.easeInOut(duration: 0.25), value: viewState.isPresentingSupplement)
            .animation(.easeInOut(duration: 0.25), value: viewState.presentation)
            .animation(.linear(duration: 0.1), value: viewState.isScrubbing)
            .alert(L10n.closePlayer, isPresented: $viewState.isPresentingCloseConfirmation) {
                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.ok, role: .destructive) {
                    manager.stop()
                }
            } message: {
                Text(L10n.closePlayerWarning)
            }
            .onReceive(viewState.containerView?.onPressEvent ?? .init()) { press in
                handlePressEvent(press)
            }
            .onDisappear {
                stopSpeedBoost()
                pendingJumpWork?.cancel()
                viewState.cancelScrub()
            }
            .onChange(of: focusCoordinator.focusedIDs) { oldIDs, newIDs in
                if oldIDs.contains(ViewState.Focus.progress),
                   !newIDs.contains(ViewState.Focus.progress)
                {
                    viewState.cancelScrub()

                    stopSpeedBoost()
                    seekingPress = nil
                }
            }
        }
    }
}
