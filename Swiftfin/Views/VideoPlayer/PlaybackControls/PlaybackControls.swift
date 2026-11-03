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

        @AdaptiveLayout
        private var viewLayout

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        private var isScrubbing: Bool {
            viewState.isScrubbing
        }

        private var supplementContent: some View {
            VideoPlayer.UIContainerViewController.SupplementContainerView()
                .frame(height: viewState.supplementHeight)
                .frame(
                    height: max(0, viewState.supplementVisibleHeight - viewState.systemInsets.bottom),
                    alignment: .top
                )
                .allowsHitTesting(viewState.visibleElements.contains(.supplements))
        }

        // MARK: body

        var body: some View {
            VideoPlayerControlsLayout(
                systemInsets: viewState.systemInsets,
                edgePadding: viewLayout.edgePadding,
                showsProgress: viewState.isPresentingProgress,
                showsSupplements: viewState.visibleElements.contains(.supplements),
                buttonsInsets: viewState.playbackButtonsInsets
            ) {
                Toolbar()
                    .frame(height: 50)
                    .isVisible(viewState.visibleElements.contains(.toolbar))
                    .enabled(viewState.visibleElements.contains(.toolbar))
                    .offset(y: viewState.isPresentingControls ? 0 : -20)
            } buttons: {
                PlaybackButtons()
                    .isVisible(viewState.visibleElements.contains(.playbackButtons))
                    .enabled(viewState.visibleElements.contains(.playbackButtons))
            } progress: {
                PlaybackProgress()
                    .isVisible(viewState.isPresentingProgress)
                    .enabled(viewState.isPresentingProgress)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        if viewState.isPresentingProgress {
                            EmptyHitTestView()
                        }
                    }
            } progressBackground: {
                Color.black
                    .mask(gradient: .linear) {
                        (location: 0, opacity: 0)
                        (location: 1, opacity: 0.5)
                    }
                    .isVisible(isScrubbing)
            } actions: {
                OverlayActions()
            } supplements: {
                supplementContent
            } toast: {
                if viewState.toastProxy.isPresenting {
                    OverlayToastContent()
                        .environmentObject(viewState.toastProxy)
                        .transition(.offset(y: -20).combined(with: .opacity))
                }
            }
            .environmentObject(viewState.toastProxy)
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.25), value: viewState.presentation)
            .animation(.easeInOut(duration: 0.2), value: viewState.toastProxy.isPresenting)
            .disabled(mediaSession.state == .error)
        }
    }
}
