//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct SleepTimerMenu: View {

        @Injected(\.mediaPlayerManager)
        private var mediaPlayerManager

        @Environment(ViewState.self)
        private var viewState

        @ContentBuilder
        var body: some View {
            let sleepTimer = mediaPlayerManager.sleepTimer

            if let deadline = mediaPlayerManager.sleepTimer.deadline {
                Menu(L10n.sleepTimer, systemImage: VideoPlayerActionButton.sleepTimer.secondarySystemImage) {
                    Button(L10n.endsAt(deadline.formatted(date: .omitted, time: .shortened))) {
                        viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.sleepTimer(sleepTimer))
                    }

                    Button(L10n.cancel, role: .destructive) {
                        sleepTimer.cancel()
                    }
                }
                .menuOrder(.fixed)
            } else {
                Button {
                    viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.sleepTimer(sleepTimer))
                } label: {
                    Label(L10n.sleepTimer, systemImage: VideoPlayerActionButton.sleepTimer.systemImage)
                }
            }
        }
    }
}
