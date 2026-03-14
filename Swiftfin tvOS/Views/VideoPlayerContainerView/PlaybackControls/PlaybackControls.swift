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

        static let supplementTransition: Animation = .easeInOut(duration: 0.35)
        static let supplementSwap: Animation = .easeInOut(duration: 0.2)

        @Default(.VideoPlayer.jumpBackwardInterval)
        var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        var jumpForwardInterval

        // since this view ignores safe area, it must
        // get safe area insets from parent views
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @OnPressEvent
        private var onPressEvent

        @EnvironmentObject
        var containerState: VideoPlayerContainerState
        @EnvironmentObject
        var manager: MediaPlayerManager

        @Toaster
        var toaster: ToastProxy

        @State
        private var bottomContentFrame: CGRect = .zero

        @State
        var speedBoostTimer: Timer?
        @State
        var isSpeedBoosting: Bool = false
        @State
        var pendingJumpWork: DispatchWorkItem?

        @EnvironmentObject
        var focusGuide: FocusGuide

        @StateObject
        private var childFocusGuide = FocusGuide()

        private var bottomContent: some View {
            VStack(spacing: 10) {
                NavigationBar()
                    .environmentObject(childFocusGuide)
                    .focusGuide(
                        focusGuide,
                        tag: "navigationBar",
                        onContentFocus: {
                            if let lastTag = childFocusGuide.lastFocusedTag ?? childFocusGuide.focusedTag {
                                childFocusGuide.transition(to: nil)
                                DispatchQueue.main.async {
                                    childFocusGuide.transition(to: lastTag)
                                }
                            } else if let firstButton = Defaults[.VideoPlayer.barActionButtons].first {
                                childFocusGuide.transition(to: firstButton.rawValue)
                            }
                        },
                        bottom: "progressBar"
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible((containerState.isPresentingOverlay || containerState.isScrubbing) && !containerState.isPresentingSupplement)
                    .disabled(containerState.isPresentingSupplement)
                    .animation(Self.supplementTransition, value: containerState.isPresentingSupplement)

                PlaybackProgress(
                    onPanScrubChanged: { isPanning in
                        if isPanning {
                            if containerState.scrubOriginSeconds == nil {
                                containerState.scrubOriginSeconds = manager.seconds
                            }
                            containerState.hasEnteredScrubMode = true
                        }
                    }
                )
                .focusSection()
                .focusGuide(
                    focusGuide,
                    tag: "progressBar",
                    top: "navigationBar",
                    bottom: "dividerZone"
                )
                .fixedSize(horizontal: false, vertical: true)
                .isVisible((containerState.isPresentingOverlay || containerState.isScrubbing) && !containerState.isPresentingSupplement)
                .disabled(containerState.isPresentingSupplement)
                .animation(Self.supplementTransition, value: containerState.isPresentingSupplement)

                Color.clear
                    .frame(height: 0)
                    .focusGuide(
                        focusGuide,
                        tag: "dividerZone",
                        onContentFocus: {
                            if focusGuide.lastFocusedTag == "tabButtons" {
                                if containerState.isPresentingSupplement {
                                    containerState.selectedSupplement = nil
                                    containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)

                                    DispatchQueue.main.async {
                                        focusGuide.transition(to: "progressBar")
                                    }
                                } else {
                                    focusGuide.transition(to: "progressBar")
                                }
                            } else {
                                focusGuide.transition(to: "tabButtons")
                            }
                        },
                        top: "progressBar",
                        bottom: "tabButtons"
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .isVisible(containerState.isPresentingOverlay)
            }
        }

        var body: some View {
            VStack(spacing: 0) {
                Spacer()
                    .allowsHitTesting(false)

                bottomContent
                    .edgePadding(.horizontal)
                    .trackingFrame($bottomContentFrame)
                    .background(alignment: .top) {
                        Color.black
                            .maskLinearGradient {
                                (location: 0, opacity: 0)
                                (location: 1, opacity: 0.5)
                            }
                            .frame(height: bottomContentFrame.height + 50 + EdgeInsets.edgePadding * 2)
                            .isVisible((containerState.isScrubbing || containerState.isPresentingOverlay) && !containerState
                                .isPresentingSupplement)
                            .allowsHitTesting(false)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.linear(duration: 0.1), value: containerState.isScrubbing)
            .animation(.easeInOut(duration: 0.25), value: containerState.isPresentingOverlay)
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
            }
            .onChange(of: containerState.isPresentingOverlay) { _, newValue in
                if newValue {
                    focusGuide.transition(to: nil)
                    DispatchQueue.main.async {
                        focusGuide.transition(to: "progressBar")
                    }
                }
            }
            .onChange(of: manager.playbackRequestStatus) { _, newValue in
                if newValue == .paused, !containerState.isPresentingOverlay {
                    containerState.isPresentingOverlay = true
                }
            }
            .onReceive(onPressEvent) { press in
                handlePressEvent(press)
            }
            .onChange(of: containerState.isProgressBarFocused) { _, newValue in
                if !newValue {
                    if containerState.hasEnteredScrubMode {
                        cancelScrubbing()
                    }
                    if isSpeedBoosting {
                        stopSpeedBoost()
                    }
                }
            }
            .onReceive(manager.secondsBox.$value) { newSeconds in
                if containerState.hasEnteredScrubMode {
                    containerState.scrubOriginSeconds = newSeconds
                }
            }
        }
    }
}
