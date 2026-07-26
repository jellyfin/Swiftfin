//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct AspectFill: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        private var isAspectFilled: Bool {
            get { containerState.isAspectFilled }
            nonmutating set { containerState.isAspectFilled = newValue }
        }

        var body: some View {
            Button {
                isAspectFilled.toggle()
            } label: {
                Group {
                    if isAspectFilled {
                        Label(
                            L10n.aspectFill,
                            systemImage: VideoPlayerActionButton.aspectFill.secondarySystemImage
                        )
                    } else {
                        Label(
                            L10n.aspectFill,
                            systemImage: VideoPlayerActionButton.aspectFill.systemImage
                        )
                    }
                }
                .videoPlayerActionButtonTransition()
            }
        }
    }
}
