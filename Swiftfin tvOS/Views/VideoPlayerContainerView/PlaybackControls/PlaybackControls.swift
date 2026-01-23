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
        private var manager: MediaPlayerManager

        @Toaster
        private var toaster: ToastProxy

        @Router
        private var router

        @State
        private var bottomContentFrame: CGRect = .zero
        @State
        private var contentSize: CGSize = .zero
        @State
        private var effectiveSafeArea: EdgeInsets = .zero

        // TODO: Cleanup. Lotta variables I think we can cleanup/combine.
        @State
        private var scrubbingTimer: Timer?
        @State
        private var scrubbingDirection: ScrubbingDirection?
        @State
        private var scrubbingSpeed: Double = 1.0
        @State
        private var scrubbingStartTime: Date?
        @State
        private var hasEnteredScrubMode: Bool = false
        @State
        private var isPresentingCloseConfirmation: Bool = false

        @FocusState
        private var isPlaybackProgressFocused: Bool

        enum ScrubbingDirection {
            case forward
            case backward
        }

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
                        .padding(.horizontal)
                        .isVisible(isPresentingOverlay || isScrubbing)

                    PlaybackProgress()
                        .isVisible(isPresentingOverlay || isScrubbing)
                        .focused($isPlaybackProgressFocused, equals: true)
                }
            }
        }

        var body: some View {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .allowsHitTesting(false)

                    bottomContent
                        .edgePadding(.horizontal)
                        .trackingFrame($bottomContentFrame)
                        .animation(.linear(duration: 0.1), value: isScrubbing)
                        .animation(.bouncy(duration: 0.4), value: isPresentingSupplement)
                        .animation(.bouncy(duration: 0.25), value: isPresentingOverlay)
                        .background(alignment: .top) {
                            Color.black
                                .maskLinearGradient {
                                    (location: 0, opacity: 0)
                                    (location: 1, opacity: 0.5)
                                }
                                .frame(height: bottomContentFrame.height + 50 + EdgeInsets.edgePadding * 2)
                                .isVisible((isScrubbing || isPresentingOverlay) && !isPresentingSupplement)
                                .animation(.linear(duration: 0.25), value: isPresentingOverlay)
                                .allowsHitTesting(false)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if manager.playbackRequestStatus == .paused {
                    Label(L10n.pause, systemImage: "pause.fill")
                        .transition(.opacity.combined(with: .scale).animation(.bouncy(duration: 0.7, extraBounce: 0.2)))
                        .font(.system(size: 72, weight: .bold, design: .default))
                        .labelStyle(.iconOnly)
                        .frame(maxHeight: .infinity)
                }
            }
            .alert("Close Player", isPresented: $isPresentingCloseConfirmation) {
                Button(L10n.cancel, role: .cancel) {}
                Button(L10n.ok, role: .destructive) {
                    manager.stop()
                }
            } message: {
                Text("Are you sure you want to close the player?")
            }
            .onFirstAppear {
                containerState.isPresentingOverlay = true
            }
            .onChange(of: containerState.isPresentingOverlay) { _, newValue in
                if newValue {
                    isPlaybackProgressFocused = true
                }
            }
            .onReceive(onPressEvent) { press in
                handlePressEvent(press)
            }
        }

        private func startScrubbing(direction: ScrubbingDirection) {
            /// If already scrubbing in same direction, increase speed
            if hasEnteredScrubMode, scrubbingDirection == direction {
                increaseScrubbingSpeed()
                return
            }

            /// If scrubbing in opposite direction, decrease speed
            if hasEnteredScrubMode, scrubbingDirection != direction {
                decreaseScrubbingSpeed(newDirection: direction)
                return
            }

            /// Start new scrubbing session
            scrubbingDirection = direction
            scrubbingStartTime = Date()
            scrubbingSpeed = 0.0
            hasEnteredScrubMode = false
            containerState.scrubbedSeconds.value = manager.seconds

            scrubbingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
                containerState.timer.poke()

                guard let startTime = scrubbingStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)

                /// After 2 seconds, activate scrubbing at 2×
                if elapsed >= 2.0 && !hasEnteredScrubMode {
                    scrubbingSpeed = 2.0
                    hasEnteredScrubMode = true
                    containerState.isScrubbing = true

                    let speedText = "\(Int(scrubbingSpeed))×"
                    toaster.present(
                        speedText,
                        systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
                    )
                }

                /// Only scrub if in scrub mode
                guard hasEnteredScrubMode else { return }

                let scrubAmount = Duration.seconds(scrubbingSpeed * 0.1)
                if direction == .forward {
                    containerState.scrubbedSeconds.value += scrubAmount
                } else {
                    containerState.scrubbedSeconds.value -= scrubAmount
                }
            }
        }

        private func increaseScrubbingSpeed() {
            if scrubbingSpeed == 2.0 {
                scrubbingSpeed = 4.0
            } else if scrubbingSpeed == 4.0 {
                scrubbingSpeed = 8.0
            } else if scrubbingSpeed == 8.0 {
                scrubbingSpeed = 16.0
            } else if scrubbingSpeed == 16.0 {
                scrubbingSpeed = 32.0
            }

            let speedText = "\(Int(scrubbingSpeed))×"
            toaster.present(
                speedText,
                systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
            )
        }

        private func decreaseScrubbingSpeed(newDirection: ScrubbingDirection) {
            if scrubbingSpeed == 2.0 {
                manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
                stopScrubbing(performJump: false)
            } else if scrubbingSpeed == 4.0 {
                scrubbingSpeed = 2.0
            } else if scrubbingSpeed == 8.0 {
                scrubbingSpeed = 4.0
            } else if scrubbingSpeed == 16.0 {
                scrubbingSpeed = 8.0
            } else if scrubbingSpeed == 32.0 {
                scrubbingSpeed = 16.0
            }

            if scrubbingSpeed > 0 {
                let speedText = "\(Int(scrubbingSpeed))×"
                toaster.present(
                    speedText,
                    systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
                )
            }
        }

        private func stopScrubbing(performJump: Bool = false) {
            scrubbingTimer?.invalidate()
            scrubbingTimer = nil

            if performJump, let direction = scrubbingDirection, !hasEnteredScrubMode {

                /// Less than 2 second selection is a jump not a scrub
                if direction == .forward {
                    containerState.jumpProgressObserver.jumpForward()
                    manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
                    toaster.present(
                        Text(
                            jumpForwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                            format: .minuteSecondsAbbreviated
                        ),
                        systemName: "goforward"
                    )
                } else {
                    containerState.jumpProgressObserver.jumpBackward()
                    manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
                    toaster.present(
                        Text(
                            jumpBackwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                            format: .minuteSecondsAbbreviated
                        ),
                        systemName: "gobackward"
                    )
                }
            } else if hasEnteredScrubMode {
                manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
            }

            containerState.isScrubbing = false
            scrubbingDirection = nil
            scrubbingSpeed = 0.0
            scrubbingStartTime = nil
            hasEnteredScrubMode = false
        }

        private func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

            /// Any remote button press should show the overlay if hidden
            if !isPresentingOverlay {
                /// Handle Pause/Play otherwies VLCKit will try to and cause conflcits
                if press.type == .playPause {
                    switch manager.playbackRequestStatus {
                    case .playing:
                        manager.setPlaybackRequestStatus(status: .paused)
                        toaster.present(L10n.pause, systemName: "pause.circle")
                    case .paused:
                        manager.setPlaybackRequestStatus(status: .playing)
                        toaster.present(L10n.play, systemName: "play.circle")
                    }
                    containerState.isPresentingOverlay = true
                    press.resolve(.handled)
                    return
                } else {
                    containerState.isPresentingOverlay = true
                    press.resolve(.fallback)
                    return
                }
            }

            switch (press.type, press.phase) {

            /// Handle arrow key scrubbing
            case (.upArrow, .began):
                if isPresentingSupplement && !isPlaybackProgressFocused {
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false)
                    containerState.timer.poke()
                    isPlaybackProgressFocused = true
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            case (.downArrow, .began):
                if !manager.supplements.isEmpty && isPlaybackProgressFocused {
                    if containerState.selectedSupplement == nil {
                        containerState.selectedSupplement = manager.supplements.first
                        containerState.containerView?.presentSupplementContainer(true)
                    }
                }
                press.resolve(.handled)

            case (.leftArrow, .began):
                if isPlaybackProgressFocused {
                    startScrubbing(direction: .backward)
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            case (.leftArrow, .ended), (.leftArrow, .cancelled):
                if scrubbingDirection == .backward, !hasEnteredScrubMode {
                    stopScrubbing(performJump: true)
                    press.resolve(.handled)
                } else if scrubbingDirection == .backward {
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            case (.rightArrow, .began):
                if isPlaybackProgressFocused {
                    startScrubbing(direction: .forward)
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            case (.rightArrow, .ended), (.rightArrow, .cancelled):
                if scrubbingDirection == .forward, !hasEnteredScrubMode {
                    stopScrubbing(performJump: true)
                    press.resolve(.handled)
                } else if scrubbingDirection == .forward {
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            case (.playPause, .began):
                if hasEnteredScrubMode {
                    manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
                    stopScrubbing(performJump: false)
                }

                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                containerState.timer.poke()
                press.resolve(.handled)

            case (.select, _):
                if hasEnteredScrubMode {
                    manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
                    stopScrubbing(performJump: false)
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            /// Use Menu Key to Open the Overlay or Close the Player
            case (.menu, _):
                if isPresentingSupplement {
                    containerState.selectedSupplement = nil
                    containerState.timer.poke()
                    press.resolve(.handled)
                } else {
                    // Show close confirmation dialog
                    isPresentingCloseConfirmation = true
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
