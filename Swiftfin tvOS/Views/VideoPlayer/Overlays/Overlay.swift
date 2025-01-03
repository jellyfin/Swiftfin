//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct Overlay: View {

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay

        @EnvironmentObject
        private var proxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var router: VideoPlayerCoordinator.Router
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager

        @State
        private var confirmCloseWorkItem: DispatchWorkItem?
        @State
        private var currentOverlayType: VideoPlayer.OverlayType = .main

        @StateObject
        private var overlayTimer: TimerProxy = .init()

        @ViewBuilder
        private var currentOverlay: some View {
            switch currentOverlayType {
            case .chapters:
                ChapterOverlay()
            case .confirmClose:
                ConfirmCloseOverlay()
            case .main:
                MainOverlay()
            case .smallMenu:
                SmallMenuOverlay()
            }
        }

        var body: some View {
            currentOverlay
                .visible(isPresentingOverlay)
                .animation(.linear(duration: 0.1), value: currentOverlayType)
                .environment(\.currentOverlayType, $currentOverlayType)
                .environmentObject(overlayTimer)
                .onChange(of: isPresentingOverlay) {
                    if !isPresentingOverlay {
                        currentOverlayType = .main
                    }
                }
                .onChange(of: currentOverlayType) { _, newValue in
                    if [.smallMenu, .chapters].contains(newValue) {
                        overlayTimer.pause()
                    } else if isPresentingOverlay {
                        overlayTimer.start(5)
                    }
                }
                .onChange(of: overlayTimer.isActive) { _, isActive in
                    guard !isActive else { return }

                    withAnimation(.linear(duration: 0.3)) {
                        isPresentingOverlay = false
                    }
                }
                .pressCommands {
                    PressCommandAction(title: L10n.back, press: .menu, action: menuPress)
                    PressCommandAction(title: L10n.playAndPause, press: .playPause) {
                        if videoPlayerManager.state == .playing {
                            videoPlayerManager.proxy.pause()
                            withAnimation(.linear(duration: 0.3)) {
                                isPresentingOverlay = true
                            }
                        } else if videoPlayerManager.state == .paused {
                            videoPlayerManager.proxy.play()
                            withAnimation(.linear(duration: 0.3)) {
                                isPresentingOverlay = false
                            }
                        }
                    }
                    PressCommandAction(title: L10n.pressDownForMenu, press: .upArrow, action: arrowPress)
                    PressCommandAction(title: L10n.pressDownForMenu, press: .downArrow, action: arrowPress)
                    PressCommandAction(title: L10n.pressDownForMenu, press: .leftArrow, action: arrowPress)
                    PressCommandAction(title: L10n.pressDownForMenu, press: .rightArrow, action: arrowPress)
                    PressCommandAction(title: L10n.pressDownForMenu, press: .select, action: arrowPress)
                }
        }

        func arrowPress() {
            if isPresentingOverlay { return }
            currentOverlayType = .main
            overlayTimer.start(5)
            withAnimation {
                isPresentingOverlay = true
            }
        }

        func menuPress() {
            overlayTimer.start(5)
            confirmCloseWorkItem?.cancel()

            if isPresentingOverlay && currentOverlayType == .confirmClose {
                proxy.stop()
                router.dismissCoordinator()
            } else if isPresentingOverlay && currentOverlayType == .smallMenu {
                currentOverlayType = .main
            } else {
                withAnimation {
                    currentOverlayType = .confirmClose
                    isPresentingOverlay = true
                }

                let task = DispatchWorkItem {
                    withAnimation {
                        isPresentingOverlay = false
                        overlayTimer.stop()
                    }
                }

                confirmCloseWorkItem = task

                DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
            }
        }
    }
}
