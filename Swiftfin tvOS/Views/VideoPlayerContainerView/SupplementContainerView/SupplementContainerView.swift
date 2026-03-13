//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import SwiftUI

// TODO: possibly make custom tab view to have observe
//       vertical scroll content and transfer to dismissal
// TODO: fix improper supplement selected
//       - maybe a race issue

extension VideoPlayer.UIVideoPlayerContainerViewController {

    struct SupplementContainerView: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var focusGuide: FocusGuide
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedSupplementID: AnyMediaPlayerSupplement.ID?

        @State
        private var lastFocusedSupplementID: AnyMediaPlayerSupplement.ID?

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isContainerVisible: Bool {
            containerState.isPresentingOverlay && !containerState.isScrubbing
        }

        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            supplement.videoPlayerBody
        }

        // TODO: scroll if larger than horizontal
        // Just adding `.scrollIfLargerThanContainer()` breaks the FocusGuide
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

        var body: some View {
            VStack(spacing: 10) {

                // MARK: Tab Buttons

                supplementTabButtons
                    .edgePadding(.horizontal)
                    .focusGuide(
                        focusGuide,
                        tag: "tabButtons",
                        onContentFocus: {
                            let targetID = lastFocusedSupplementID
                                ?? containerState.selectedSupplement?.id
                                ?? currentSupplements.first?.id
                            focusedSupplementID = targetID
                        },
                        top: "dividerZone",
                        bottom: isPresentingSupplement ? "supplementContent" : nil
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(alignment: .leading)
                    .isVisible(isContainerVisible && !currentSupplements.isEmpty)
                    .transaction { $0.animation = nil }

                // MARK: Supplement Content

                ZStack {
                    if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                        supplementContainer(for: supplement)
                            .eraseToAnyView()
                            .transition(.opacity)
                    } else {
                        ForEach(currentSupplements) { anySupplement in
                            supplementContainer(for: anySupplement.supplement)
                                .eraseToAnyView()
                                .opacity(containerState.selectedSupplement?.id == anySupplement.id ? 1 : 0)
                                .disabled(containerState.selectedSupplement?.id != anySupplement.id)
                        }
                    }
                }
                .focusSection()
                .focusGuide(
                    focusGuide,
                    tag: "supplementContent",
                    top: "tabButtons"
                )
                .isVisible(isPresentingSupplement)
                .disabled(!isPresentingSupplement)
                .animation(VideoPlayer.PlaybackControls.supplementTransition, value: isPresentingSupplement)
                .animation(VideoPlayer.PlaybackControls.supplementSwap, value: containerState.selectedSupplement?.id)
            }
            .background {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black.opacity(0.7), location: 0.15),
                        .init(color: .black.opacity(0.85), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .padding(.bottom, -200)
                .isVisible(isPresentingSupplement)
                .allowsHitTesting(false)
            }
            .isVisible(isContainerVisible)
            .animation(.linear(duration: 0.15), value: isContainerVisible)
            .environment(\.isOverComplexContent, true)
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
            .onReceive(manager.$playbackItem) { newItem in
                guard newItem != nil else { return }

                // Supplement IDs change with the playbackItem
                // Reset these to prevent FocusGuide breakages where the lastFocused IDs are invalid
                containerState.selectedSupplement = nil
                containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
                focusedSupplementID = nil
                lastFocusedSupplementID = nil

                DispatchQueue.main.async {
                    focusGuide.transition(to: nil)
                    focusGuide.transition(to: focusGuide.lastFocusedTag)
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
