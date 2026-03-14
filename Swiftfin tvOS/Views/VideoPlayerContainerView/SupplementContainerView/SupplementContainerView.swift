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
                } else {
                    ForEach(currentSupplements) { supplement in
                        Button {
                            containerState.selectedSupplement = supplement.supplement
                            containerState.containerView?.presentSupplementContainer(true)
                        } label: {
                            Text(supplement.displayTitle)
                        }
                        .buttonStyle(SupplementTitleButtonStyle())
                        .isSelected(containerState.selectedSupplement?.id == supplement.id)
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
                            focusedSupplementID = lastFocusedSupplementID
                                ?? containerState.selectedSupplement?.id
                                ?? currentSupplements.first?.id
                        },
                        top: "dividerZone",
                        bottom: containerState.isPresentingSupplement ? "supplementContent" : nil
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(alignment: .leading)
                    .isVisible((containerState.isPresentingOverlay && !containerState.isScrubbing) && !currentSupplements.isEmpty)
                    .transaction { $0.animation = nil }

                // MARK: Supplement Content

                ZStack {
                    if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                        supplementContainer(for: supplement)
                            .eraseToAnyView()
                            .transition(.opacity)
                    } else if let selected = containerState.selectedSupplement,
                              let anySupplement = currentSupplements[id: selected.id]
                    {
                        supplementContainer(for: anySupplement.supplement)
                            .eraseToAnyView()
                            .transition(.opacity)
                    }
                }
                .focusSection()
                .focusGuide(
                    focusGuide,
                    tag: "supplementContent",
                    top: "tabButtons"
                )
                .isVisible(containerState.isPresentingSupplement)
                .disabled(!containerState.isPresentingSupplement)
                .animation(VideoPlayer.PlaybackControls.supplementTransition, value: containerState.isPresentingSupplement)
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
                .isVisible(containerState.isPresentingSupplement)
                .allowsHitTesting(false)
            }
            .isVisible(containerState.isPresentingOverlay && !containerState.isScrubbing)
            .animation(.linear(duration: 0.15), value: containerState.isPresentingOverlay && !containerState.isScrubbing)
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
                guard oldValue != newValue, let newValue else { return }

                lastFocusedSupplementID = newValue

                if let supplement = currentSupplements[id: newValue] {
                    containerState.selectedSupplement = supplement.supplement
                    containerState.containerView?.presentSupplementContainer(true, redirectFocus: false)
                }
            }
        }
    }
}
