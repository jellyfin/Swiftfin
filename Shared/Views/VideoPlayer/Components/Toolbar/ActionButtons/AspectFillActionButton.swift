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

        @Environment(ViewState.self)
        private var viewState

        var body: some View {
            Button(
                L10n.aspectFill,
                systemImage: viewState.aspectFillBehavior == .fill ?
                    VideoPlayerActionButton.aspectFill.secondarySystemImage :
                    VideoPlayerActionButton.aspectFill.systemImage
            ) {
                viewState.toggleAspectFillBehavior()
            }
        }
    }
}
