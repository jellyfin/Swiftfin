//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct AutoPlay: View {

        @Default(.VideoPlayer.autoPlayEnabled)
        private var isAutoPlayEnabled

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        private var systemImage: String {
            if isAutoPlayEnabled {
                "play.circle.fill"
            } else {
                "stop.circle"
            }
        }

        var body: some View {
            Button {
                isAutoPlayEnabled.toggle()

//                if isAutoPlayEnabled {
//                    toastProxy.present("Auto Play enabled", systemName: "play.circle.fill")
//                } else {
//                    toastProxy.present("Auto Play disabled", systemName: "stop.circle")
//                }
            } label: {
                Label(
                    L10n.autoPlay,
                    systemImage: systemImage
                )

                if isInMenu {
                    Text(isAutoPlayEnabled ? "On" : "Off")
                }
            }
            .videoPlayerActionButtonTransition()
            .id(isAutoPlayEnabled)
            .disabled(manager.queue == nil)
        }
    }
}
