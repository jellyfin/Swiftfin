//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension LiveVideoPlayer {

    struct LiveMainOverlay: View {

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var currentProgressHandler: LiveVideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy

        var body: some View {
            VStack {

                Spacer()

                Overlay.LiveBottomBarView()
                    .padding()
                    .padding()
                    .background {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black.opacity(0.8), location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            }
            .environmentObject(overlayTimer)
        }
    }
}
