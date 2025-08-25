//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: supplement transition animation fixes
// TODO: have overlay show after presentation/rotation
// TODO: error state

extension VideoPlayer {

    struct PlaybackControls: View {

        // TODO: move to containerState
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

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

        // TODO: move to containerstate
        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init()

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        // MARK: body

        var body: some View {
            ZStack {

                // MARK: - Dark

                // TODO: keep only bottom gradient on scrubbing
//                ZStack(alignment: .bottom) {
//
//                    Color.black
//                        .isVisible(opacity: 0.5, !isScrubbing && containerState.isPresentingOverlay)
//                        .allowsHitTesting(false)
//
//                    Color.black
//                        .maskLinearGradient {
//                            (location: 0, opacity: 0)
//                            (location: 1, opacity: 0.5)
//                        }
//                        .isVisible(isScrubbing)
//                        .frame(height: bottomContentFrame.height)
//                }
//                .animation(.linear(duration: 0.25), value: containerState.containerState.isPresentingOverlay)

                // MARK: - Buttons and Supplements

                VStack {
                    NavigationBar()
                        .isVisible(!isScrubbing && containerState.isPresentingOverlay)
                        .padding(.top, safeAreaInsets.top)
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .offset(y: containerState.isPresentingOverlay ? 0 : -20)
                        .frame(height: 50)

                    Spacer()
                        .allowsHitTesting(false)

                    ZStack {
                        if !isPresentingSupplement {
                            PlaybackProgress()
                                .isVisible(isScrubbing || containerState.isPresentingOverlay)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: containerState.isPresentingOverlay ? 0 : 20)
                    .trackingFrame($bottomContentFrame)
                    .padding(.leading, safeAreaInsets.leading)
                    .padding(.trailing, safeAreaInsets.trailing)
                    .background {
                        if containerState.isPresentingOverlay {
                            EmptyHitTestView()
                        }
                    }
                    .padding(.bottom, safeAreaInsets.bottom)
                }

                if !isPresentingSupplement {
                    PlaybackButtons()
                        .isVisible(!isScrubbing && containerState.isPresentingOverlay)
                        .transition(.opacity)
                }
            }
            .modifier(VideoPlayer.KeyCommandsModifier())
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
            .animation(.bouncy(duration: 0.25), value: containerState.isPresentingOverlay)
            .environment(\.isPresentingOverlay, $containerState.isPresentingOverlay)
            .environmentObject(jumpProgressObserver)
            .environmentObject(overlayTimer)
            .onChange(of: containerState.isPresentingOverlay) { newValue in
                guard newValue, !isScrubbing else { return }
                overlayTimer.poke()
            }
            .onChange(of: isScrubbing) { newValue in
                if newValue {
                    overlayTimer.stop()
                } else {
                    overlayTimer.poke()
                }
            }
            .onReceive(overlayTimer.hasFired) { _ in
                guard !isScrubbing else { return }

                withAnimation(.linear(duration: 0.25)) {
                    containerState.isPresentingOverlay = false
                }
            }
//            .onChange(of: selectedSupplement) { newValue in
//                if newValue == nil {
//                    overlayTimer.poke()
//                } else {
//                    overlayTimer.stop()
//                }
//            }
        }
    }
}
