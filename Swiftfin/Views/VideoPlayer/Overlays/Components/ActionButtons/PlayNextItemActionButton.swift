//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct PlayNextItem: View {

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager

        private var content: () -> any View

        var body: some View {
            Button {
                videoPlayerManager.selectNextViewModel()
                overlayTimer.start(5)
            } label: {
                content()
                    .eraseToAnyView()
            }
            .disabled(videoPlayerManager.nextViewModel == nil)
            .foregroundColor(videoPlayerManager.nextViewModel == nil ? .gray : .white)
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.PlayNextItem {

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }
}
