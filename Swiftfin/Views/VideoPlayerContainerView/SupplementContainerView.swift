//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension UIVideoPlayerContainerViewController {

    struct SupplementContainerView: View {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var isPresentingOverlay: Bool {
            containerState.isPresentingOverlay
        }

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

        var body: some View {
            ZStack {
                GestureView()

                VStack(spacing: EdgeInsets.edgePadding) {
                    HStack(spacing: 10) {
                        ForEach(manager.supplements.map(\.asAny)) { supplement in
                            let isSelected = containerState.selectedSupplement?.id == supplement.id

                            Button(supplement.displayTitle) {
                                if isSelected {
                                    containerState.selectedSupplement = nil
                                } else {
                                    containerState.selectedSupplement = supplement
                                }
                            }
                            .isSelected(isSelected)
                        }
                    }
                    .buttonStyle(SupplementTitleButtonStyle())
                    .padding(.leading, safeAreaInsets.leading)
                    .padding(.trailing, safeAreaInsets.trailing)
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    AlternateLayoutView(alignment: .topLeading) {
                        Color.clear
                    } content: {
                        if let selectedSupplement = containerState.selectedSupplement {
                            selectedSupplement
                                .videoPlayerBody
                                .transition(.opacity.animation(.linear(duration: 0.4)))
                                .padding(.bottom, EdgeInsets.edgePadding)
                        }
                    }
                }
                .isVisible(isPresentingOverlay)
                .isVisible(!isScrubbing)
            }
            .animation(.linear(duration: 0.2), value: isPresentingOverlay)
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}
