//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        private var manager: MediaPlayerManager

        @State
        private var currentSupplements: IdentifiedArrayOf<AnyMediaPlayerSupplement> = []

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        @ViewBuilder
        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            AlternateLayoutView(alignment: .topLeading) {
                Color.clear
            } content: {
                supplement.videoPlayerBody
            }
            .background {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)
            }
        }

        var body: some View {
            ZStack {
                GestureView()
                    .environment(\.panGestureDirection, containerState.presentationControllerShouldDismiss ? .up : .vertical)

                VStack(spacing: EdgeInsets.edgePadding) {

                    // TODO: scroll if larger than horizontal
                    HStack(spacing: 10) {
                        if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                            Button(supplement.displayTitle) {
                                containerState.select(supplement: nil)
                            }
                            .isSelected(true)
                        } else {
                            ForEach(currentSupplements) { supplement in
                                let isSelected = containerState.selectedSupplement?.id == supplement.id

                                Button(supplement.displayTitle) {
                                    containerState.select(supplement: supplement.supplement)
                                }
                                .isSelected(isSelected)
                            }
                        }
                    }
                    .buttonStyle(SupplementTitleButtonStyle())
                    .padding(.leading, safeAreaInsets.leading)
                    .padding(.trailing, safeAreaInsets.trailing)
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        if containerState.isGuestSupplement, let supplement = containerState.selectedSupplement {
                            supplementContainer(for: supplement)
                                .eraseToAnyView()
                        } else {
                            TabView(
                                selection: $containerState.selectedSupplement.map(
                                    getter: { $0?.id },
                                    setter: { id -> (any MediaPlayerSupplement)? in
                                        id.map { currentSupplements[id: $0]?.supplement } ?? nil
                                    }
                                )
                            ) {
                                ForEach(currentSupplements) { supplement in
                                    supplementContainer(for: supplement.supplement)
                                        .eraseToAnyView()
                                        .tag(supplement.id as String?)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                        }
                    }
                    .isVisible(containerState.isPresentingSupplement)
                    .disabled(!containerState.isPresentingSupplement)
                    .animation(.linear(duration: 0.2), value: containerState.selectedSupplement?.id)
                }
                .edgePadding(.top)
                .isVisible(isPresentingOverlay)
                .isVisible(!isScrubbing)
            }
            .animation(.linear(duration: 0.2), value: isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.1), value: currentSupplements)
            .environment(\.isOverComplexContent, true)
            .onReceive(manager.$supplements) { newValue in
                let newSupplements = IdentifiedArray(
                    uniqueElements: newValue.map(AnyMediaPlayerSupplement.init)
                )
                currentSupplements = newSupplements
            }
            .environment(
                \.panAction,
                .init(
                    action: {
                        containerState.containerView?.handlePanGesture(
                            translation: $0,
                            velocity: $1,
                            location: $2,
                            unitPoint: $3,
                            state: $4
                        )
                    }
                )
            )
            .environment(
                \.tapGestureAction,
                .init(
                    action: {
                        containerState.containerView?.handleTapGesture(
                            location: $0,
                            unitPoint: $1,
                            count: $2
                        )
                    }
                )
            )
        }
    }
}
