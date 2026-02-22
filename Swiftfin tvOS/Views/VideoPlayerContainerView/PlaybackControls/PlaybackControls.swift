//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import IdentifiedCollections
import SwiftUI

extension VideoPlayer {

    struct PlaybackControls: View {

        private typealias SupplementTitleButtonStyle = VideoPlayer.UIVideoPlayerContainerViewController
            .SupplementContainerView.SupplementTitleButtonStyle

        // MARK: - Defaults

        @Default(.VideoPlayer.jumpBackwardInterval)
        var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        var jumpForwardInterval

        // MARK: - Environment

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

        // MARK: - State (Layout)

        @State
        private var bottomContentFrame: CGRect = .zero

        // MARK: - State (Speed Boost / Jump)

        @State
        var speedBoostTimer: Timer?
        @State
        var isSpeedBoosting: Bool = false
        @State
        var pendingJumpWork: DispatchWorkItem?

        // MARK: - Focus

        @EnvironmentObject
        var focusGuide: FocusGuide

        @FocusState
        var focusedActionButton: VideoPlayerActionButton?

        @FocusState
        var focusedSupplementID: AnyMediaPlayerSupplement.ID?

        @State
        private var lastFocusedActionButton: VideoPlayerActionButton?

        @State
        private var lastFocusedSupplementID: AnyMediaPlayerSupplement.ID?

        var isProgressBarFocused: Bool {
            containerState.isProgressBarFocused
        }

        // MARK: - State (Supplements)

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        // MARK: - Computed Properties

        var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        var hasEnteredScrubMode: Bool {
            get { containerState.hasEnteredScrubMode }
            nonmutating set { containerState.hasEnteredScrubMode = newValue }
        }

        var scrubOriginSeconds: Duration? {
            get { containerState.scrubOriginSeconds }
            nonmutating set { containerState.scrubOriginSeconds = newValue }
        }

        // MARK: - View Builders

        // TODO: scroll if larger than horizontal
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
                NavigationBar(focusedActionButton: $focusedActionButton)
                    .focusGuide(
                        focusGuide,
                        tag: "navigationBar",
                        fixedSize: (horizontal: false, vertical: true),
                        onContentFocus: {
                            focusedActionButton = lastFocusedActionButton
                                ?? Defaults[.VideoPlayer.barActionButtons].first
                        },
                        bottom: "progressBar"
                    )
                    .isVisible((isPresentingOverlay || isScrubbing) && !isPresentingSupplement)
                    .disabled(isPresentingSupplement)

                PlaybackProgress(
                    onPanScrubChanged: { isPanning in
                        if isPanning {
                            if scrubOriginSeconds == nil {
                                scrubOriginSeconds = manager.seconds
                            }
                            hasEnteredScrubMode = true
                        }
                    }
                )
                .focusGuide(
                    focusGuide,
                    tag: "progressBar",
                    fixedSize: (horizontal: false, vertical: true),
                    top: "navigationBar",
                    bottom: currentSupplements.isEmpty ? nil : "dividerZone"
                )
                .isVisible((isPresentingOverlay || isScrubbing) && !isPresentingSupplement)
                .disabled(isPresentingSupplement)

                Color.clear
                    .frame(height: 0)
                    .focusGuide(
                        focusGuide,
                        tag: "dividerZone",
                        fixedSize: (horizontal: false, vertical: true),
                        onContentFocus: {
                            if focusGuide.lastFocusedTag == "tabButtons" {
                                if isPresentingSupplement {
                                    // Dismiss supplement then redirect after hierarchy updates
                                    containerState.selectedSupplement = nil
                                    containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)

                                    DispatchQueue.main.async {
                                        focusGuide.transition(to: "progressBar")
                                    }
                                } else {
                                    focusGuide.transition(to: "progressBar")
                                }
                            } else {
                                // Coming from above (progressBar) pass through to tabs
                                focusGuide.transition(to: "tabButtons")
                            }
                        },
                        top: "progressBar",
                        bottom: "tabButtons"
                    )
                    .isVisible(isPresentingOverlay)

                supplementTabButtons
                    .focusGuide(
                        focusGuide,
                        tag: "tabButtons",
                        fixedSize: (horizontal: false, vertical: true),
                        onContentFocus: {
                            let targetID = lastFocusedSupplementID
                                ?? containerState.selectedSupplement?.id
                                ?? currentSupplements.first?.id
                            focusedSupplementID = targetID
                        },
                        top: "dividerZone",
                        bottom: isPresentingSupplement ? "supplementContent" : nil
                    )
                    .isVisible(isPresentingOverlay && !currentSupplements.isEmpty)
            }
        }

        // MARK: body

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
                            .isVisible((isScrubbing || isPresentingOverlay) && !isPresentingSupplement)
                            .allowsHitTesting(false)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.easeInOut(duration: 0.3), value: isPresentingSupplement)
            .animation(.easeInOut(duration: 0.25), value: isPresentingOverlay)
            .alert("Close Player", isPresented: $containerState.isPresentingCloseConfirmation) {
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
                    focusGuide.transition(to: nil)
                    DispatchQueue.main.async {
                        focusGuide.transition(to: "progressBar")
                    }
                }
            }
            .onChange(of: manager.playbackRequestStatus) { _, newValue in
                if newValue == .paused, !isPresentingOverlay {
                    containerState.isPresentingOverlay = true
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
                guard newSupplements.ids != currentSupplements.ids else { return }
                currentSupplements = newSupplements
            }
            .onChange(of: focusedActionButton) { _, newValue in
                if let newValue {
                    lastFocusedActionButton = newValue
                }
            }
            .onChange(of: containerState.isProgressBarFocused) { _, newValue in
                if !newValue {
                    if hasEnteredScrubMode {
                        cancelScrubbing()
                    }
                    if isSpeedBoosting {
                        stopSpeedBoost()
                    }
                }
            }
            .onReceive(manager.secondsBox.$value) { newSeconds in
                if hasEnteredScrubMode {
                    scrubOriginSeconds = newSeconds
                }
            }
            .onChange(of: focusedSupplementID) { oldValue, newValue in
                if let newValue {
                    lastFocusedSupplementID = newValue
                }

                guard oldValue != newValue else { return }
                guard let supplementID = newValue else { return }

                if let supplement = currentSupplements[id: supplementID] {
                    containerState.selectedSupplement = supplement.supplement
                    containerState.containerView?.presentSupplementContainer(true, redirectFocus: false)
                }
            }
        }
    }
}
