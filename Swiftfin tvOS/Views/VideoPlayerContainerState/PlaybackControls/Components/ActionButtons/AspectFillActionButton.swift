//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct AspectFill: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        private var isAspectFilled: Bool {
            get { containerState.isAspectFilled }
            nonmutating set { containerState.isAspectFilled = newValue }
        }

        private var systemImage: String {
            if isAspectFilled {
                VideoPlayerActionButton.aspectFill.secondarySystemImage
            } else {
                VideoPlayerActionButton.aspectFill.systemImage
            }
        }

        var body: some View {
            Button(
                L10n.aspectFill,
                systemImage: systemImage
            ) {
                isAspectFilled.toggle()
            }
//            .videoPlayerActionButtonTransition()
//            .id(isAspectFilled)
        }
    }
}
