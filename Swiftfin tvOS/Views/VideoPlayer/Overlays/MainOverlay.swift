//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer {

    struct MainOverlay: View {

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
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy

        var body: some View {
            VStack {

                Spacer()

                tvOSSliderView(value: $currentProgressHandler.scrubbedProgress)
                    .onEditingChanged { isEditing in
                        isScrubbing = isEditing

                        if isEditing {
                            overlayTimer.pause()
                        } else {
                            overlayTimer.start(5)
                        }
                    }
                    .visible(isScrubbing || isPresentingOverlay)
                    .frame(height: 100)
                    .padding()
            }
            .environmentObject(overlayTimer)
        }
    }
}
