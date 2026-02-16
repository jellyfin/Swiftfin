//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import IdentifiedCollections
import SwiftUI

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

        private var isPresentingSupplement: Bool {
            containerState.isPresentingSupplement
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        private func supplementContainer(for supplement: some MediaPlayerSupplement) -> some View {
            supplement.videoPlayerBody
                .background {
                    GestureView()
                        .environment(\.panGestureDirection, .vertical)
                }
        }

        // MARK: body

        var body: some View {
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
            .isVisible(containerState.isPresentingSupplement)
            .disabled(!containerState.isPresentingSupplement)
            .animation(.easeInOut(duration: 0.25), value: containerState.isPresentingSupplement)
            .animation(.easeInOut(duration: 0.2), value: containerState.selectedSupplement?.id)
            .padding(.top, 10)
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
            .isVisible(isPresentingOverlay)
            .isVisible(!isScrubbing)
            .animation(.linear(duration: 0.2), value: isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.bouncy(duration: 0.3, extraBounce: 0.1), value: currentSupplements)
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
                currentSupplements = newSupplements
            }
        }
    }
}
