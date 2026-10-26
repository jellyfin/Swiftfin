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
        @Environment(MediaSession.self)
        var mediaSession

        @EnvironmentObject
        private var focusCoordinator: FocusCoordinator

        @State
        var seekingPress: UIPress.PressType?
        @State
        var speedBoostTimer: Timer?
        @State
        var isSpeedBoosting: Bool = false

        @Toaster
        var toaster: ToastProxy

        var body: some View {
            @Bindable
            var viewState = viewState

            VStack(spacing: 0) {

                Toolbar()
                    .isVisible(viewState.visibleElements.contains(.toolbar))
                    .enabled(viewState.visibleElements.contains(.toolbar))
                    .padding(.bottom, 30)

                PlaybackProgress()
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(viewState.isPresentingProgress)
                    .enabled(viewState.isPresentingProgress)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                        viewState.bottomControlsHeight = $0 + Toolbar.buttonSize
                    }
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
                    mediaSession.stop()
                }
            } message: {
                Text(L10n.closePlayerWarning)
            }
            .onReceive(viewState.containerView?.onPressEvent ?? .init()) { press in
                handlePressEvent(press)
            }
            .onDisappear {
                stopSpeedBoost()
                viewState.cancelScrub()
            }
            .onChange(of: mediaSession.playbackItem.map(ObjectIdentifier.init), initial: true) { _, _ in
                stopSpeedBoost()
                seekingPress = nil
                viewState.jumpProgressObserver.reset()
            }
            .onReceive(
                focusCoordinator.$focusedIDs
                    .map { $0.contains(ViewState.Focus.progress) }
                    .removeDuplicates()
                    .dropFirst()
            ) { isFocused in
                guard !isFocused else { return }

                viewState.cancelScrub()

                stopSpeedBoost()
                seekingPress = nil
            }
        }
    }
}
