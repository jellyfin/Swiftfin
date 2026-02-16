//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import IdentifiedCollections
import PreferencesView
import SwiftUI
import VLCUI

extension VideoPlayer {

    struct PlaybackControls: View {

        private typealias SupplementTitleButtonStyle = VideoPlayer.UIVideoPlayerContainerViewController
            .SupplementContainerView.SupplementTitleButtonStyle

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        /// since this view ignores safe area, it must
        /// get safe area insets from parent views
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

        @State
        private var pendingJumpWork: DispatchWorkItem?

        @FocusState
        private var isPlaybackProgressFocused: Bool
        @FocusState
        private var focusedSupplementID: AnyMediaPlayerSupplement.ID?

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        private enum ScrubbingDirection {
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

        private var supplementTabButtons: some View {
            HStack(spacing: 20) {
                if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                    Button {
                        containerState.select(supplement: nil)
                    } label: {
                        Text(supplement.displayTitle)
                    }
                    .buttonStyle(SupplementTitleButtonStyle())
                    .isSelected(true)
                    .focused($focusedSupplementID, equals: supplement.id)
                } else {
                    ForEach(currentSupplements) { supplement in
                        Button {
                            containerState.selectedSupplement = supplement.supplement
                            containerState.containerView?.presentSupplementContainer(true)
                        } label: {
                            Text(supplement.displayTitle)
                        }
                        .buttonStyle(SupplementTitleButtonStyle())
                        .isSelected(
                            focusedSupplementID == supplement.id ||
                                (focusedSupplementID == nil && containerState.selectedSupplement?.id == supplement.id)
                        )
                        .focused($focusedSupplementID, equals: supplement.id)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .focusSection()
        }

        private var bottomContent: some View {
            VStack(spacing: 0) {
                if !isPresentingSupplement {
                    NavigationBar()
                        .isVisible(isPresentingOverlay || isScrubbing)

                    PlaybackProgress()
                        .isVisible(isPresentingOverlay || isScrubbing)
                        .focused($isPlaybackProgressFocused, equals: true)
                }

                supplementTabButtons
                    .padding(.top, isPresentingSupplement ? 0 : 20)
                    .isVisible(isPresentingOverlay && !isScrubbing && !currentSupplements.isEmpty)
            }
        }

        // MARK: body

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
            .onChange(of: manager.playbackRequestStatus) { _, newValue in
                if newValue == .paused, !isPresentingOverlay {
                    containerState.isPresentingOverlay = true
                }
            }
            .onChange(of: isPlaybackProgressFocused) { _, newValue in
                if newValue && isPresentingSupplement {
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
                }
            }
            .onReceive(onPressEvent) { press in
                handlePressEvent(press)
            }
            .onAppear {
                let initial = IdentifiedArray(
                    uniqueElements: manager.supplements.map(AnyMediaPlayerSupplement.init)
                )
                if currentSupplements.isEmpty && !initial.isEmpty {
                    currentSupplements = initial
                }
            }
            .onReceive(manager.$supplements) { newValue in
                let newSupplements = IdentifiedArray(
                    uniqueElements: newValue.map(AnyMediaPlayerSupplement.init)
                )
                currentSupplements = newSupplements
            }
            .onChange(of: focusedSupplementID) { oldValue, newValue in
                guard oldValue != newValue else { return }
                guard let supplementID = newValue else { return }
                guard !isRedirectingToTab else { return }

                if oldValue == nil {
                    if let selectedID = containerState.selectedSupplement?.id, supplementID != selectedID {
                        focusedSupplementID = selectedID
                        return
                    } else if containerState.selectedSupplement == nil,
                              let firstID = currentSupplements.first?.id,
                              supplementID != firstID
                    {
                        focusedSupplementID = firstID
                        return
                    }
                }

                if let supplement = currentSupplements[id: supplementID] {
                    containerState.selectedSupplement = supplement.supplement
                    containerState.containerView?.presentSupplementContainer(true, redirectFocus: false)
                }
            }
        }

        // MARK: - Scrubbing

        private func startScrubbing(direction: ScrubbingDirection) {
            if hasEnteredScrubMode, scrubbingDirection == direction {
                increaseScrubbingSpeed()
                return
            }

            if hasEnteredScrubMode, scrubbingDirection != direction {
                decreaseScrubbingSpeed(newDirection: direction)
                return
            }

            scrubbingDirection = direction
            scrubbingStartTime = Date()
            scrubbingSpeed = 0.0
            hasEnteredScrubMode = false
            containerState.scrubbedSeconds.value = manager.seconds

            scrubbingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
                containerState.timer.poke()

                guard let startTime = scrubbingStartTime else { return }
                let elapsed = Date().timeIntervalSince(startTime)

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

            toaster.present(
                "\(Int(scrubbingSpeed))×",
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
                toaster.present(
                    "\(Int(scrubbingSpeed))×",
                    systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
                )
            }
        }

        private func stopScrubbing(performJump: Bool = false) {
            scrubbingTimer?.invalidate()
            scrubbingTimer = nil

            if performJump, let direction = scrubbingDirection, !hasEnteredScrubMode {
                if direction == .forward {
                    containerState.jumpProgressObserver.jumpForward()
                    toaster.present(
                        Text(
                            jumpForwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                            format: .minuteSecondsAbbreviated
                        ),
                        systemName: "goforward"
                    )
                    scheduleJump(direction: .forward)
                } else {
                    containerState.jumpProgressObserver.jumpBackward()
                    toaster.present(
                        Text(
                            jumpBackwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                            format: .minuteSecondsAbbreviated
                        ),
                        systemName: "gobackward"
                    )
                    scheduleJump(direction: .backward)
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

        private func scheduleJump(direction: ScrubbingDirection) {
            pendingJumpWork?.cancel()

            let jumpCount = containerState.jumpProgressObserver.jumps
            let interval = direction == .forward
                ? jumpForwardInterval.rawValue
                : jumpBackwardInterval.rawValue

            let work = DispatchWorkItem { [weak manager] in
                let totalDuration = interval * jumpCount
                if direction == .forward {
                    manager?.proxy?.jumpForward(totalDuration)
                } else {
                    manager?.proxy?.jumpBackward(totalDuration)
                }
            }

            pendingJumpWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
        }

        // MARK: - Focus Zone

        private enum FocusZone {
            case navBar
            case progressBar
            case tabButtons
            case supplementContent
        }

        @State
        private var pressBeganZone: FocusZone?
        @State
        private var isRedirectingToTab: Bool = false

        private var currentFocusZone: FocusZone {
            if isPlaybackProgressFocused {
                return .progressBar
            } else if focusedSupplementID != nil {
                return .tabButtons
            } else if isPresentingSupplement {
                return .supplementContent
            } else {
                return .navBar
            }
        }

        // MARK: - Press Event Handling

        private func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

            if !isPresentingOverlay {
                if press.type == .playPause {
                    if manager.playbackRequestStatus == .paused {
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

            if press.phase == .began {
                pressBeganZone = currentFocusZone
            }

            let zone = pressBeganZone ?? currentFocusZone

            switch (press.type, press.phase) {

            // MARK: Up Arrow

            case (.upArrow, .began):
                switch zone {
                case .tabButtons, .supplementContent:
                    press.resolve(.handled)
                default:
                    press.resolve(.fallback)
                }

            case (.upArrow, .ended):
                switch zone {
                case .tabButtons:
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
                    containerState.timer.poke()
                    isPlaybackProgressFocused = true
                    press.resolve(.handled)
                case .supplementContent:
                    let targetID = containerState.selectedSupplement?.id ?? currentSupplements.first?.id
                    isRedirectingToTab = true
                    containerState.containerView?.redirectFocusToPlaybackControls()
                    containerState.timer.poke()
                    DispatchQueue.main.async {
                        focusedSupplementID = targetID
                        isRedirectingToTab = false
                    }
                    press.resolve(.handled)
                default:
                    press.resolve(.fallback)
                }

            // MARK: Down Arrow

            case (.downArrow, .began):
                switch zone {
                case .progressBar where !currentSupplements.isEmpty,
                     .tabButtons where isPresentingSupplement:
                    press.resolve(.handled)
                default:
                    press.resolve(.fallback)
                }

            case (.downArrow, .ended):
                switch zone {
                case .progressBar where !currentSupplements.isEmpty:
                    let targetID = containerState.selectedSupplement?.id ?? currentSupplements.first?.id
                    focusedSupplementID = targetID
                    containerState.timer.poke()
                    press.resolve(.handled)
                case .tabButtons where isPresentingSupplement:
                    containerState.supplementContentNeedsFocus = true
                    containerState.containerView?.redirectFocusToSupplementContent()
                    containerState.timer.poke()
                    press.resolve(.handled)
                default:
                    press.resolve(.fallback)
                }

            // MARK: Left Arrow

            case (.leftArrow, .began):
                if zone == .progressBar {
                    startScrubbing(direction: .backward)
                    press.resolve(.handled)
                } else if zone == .tabButtons {
                    if let currentID = focusedSupplementID,
                       let currentIndex = currentSupplements.index(id: currentID),
                       currentIndex > currentSupplements.startIndex
                    {
                        let previousIndex = currentSupplements.index(before: currentIndex)
                        focusedSupplementID = currentSupplements[previousIndex].id
                    }
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
                } else if zone == .tabButtons {
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            // MARK: Right Arrow

            case (.rightArrow, .began):
                if zone == .progressBar {
                    startScrubbing(direction: .forward)
                    press.resolve(.handled)
                } else if zone == .tabButtons {
                    if let currentID = focusedSupplementID,
                       let currentIndex = currentSupplements.index(id: currentID)
                    {
                        let nextIndex = currentSupplements.index(after: currentIndex)
                        if nextIndex < currentSupplements.endIndex {
                            focusedSupplementID = currentSupplements[nextIndex].id
                        }
                    }
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
                } else if zone == .tabButtons {
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            // MARK: Play/Pause

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

            // MARK: Select

            case (.select, _):
                if hasEnteredScrubMode {
                    manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
                    stopScrubbing(performJump: false)
                    manager.setPlaybackRequestStatus(status: .playing)
                    containerState.timer.poke()
                    press.resolve(.handled)
                } else {
                    press.resolve(.fallback)
                }

            // MARK: Menu

            case (.menu, _):
                if isPresentingSupplement {
                    containerState.selectedSupplement = nil
                    containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
                    containerState.timer.poke()
                    isPlaybackProgressFocused = true
                    press.resolve(.handled)
                } else {
                    isPresentingCloseConfirmation = true
                    press.resolve(.handled)
                }

            default:
                containerState.timer.poke()
                press.resolve(.fallback)
            }
        }
    }
}
