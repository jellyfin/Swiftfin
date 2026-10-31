//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

// TODO: static width for tvOS

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct AutoPlay: View {

        @AdaptiveLayout
        private var viewLayout

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @Environment(MediaSession.self)
        private var mediaSession

        @State
        private var userConfiguration: UserConfiguration

        @StateObject
        private var viewModel: ServerUserAdminViewModel

        @Toaster
        private var toaster

        private var isAutoPlayEnabled: Bool {
            mediaSession.userSession.user.data.configuration?.enableNextEpisodeAutoPlay == true
        }

        private var systemImage: String {
            if isAutoPlayEnabled {
                VideoPlayerActionButton.autoPlay.systemImage
            } else {
                VideoPlayerActionButton.autoPlay.secondarySystemImage
            }
        }

        init() {
            let user = Container.shared.currentUserSession()?.user.data ?? UserDto()

            self.userConfiguration = user.configuration ?? UserConfiguration()
            self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        }

        var body: some View {
            Button {
                let newValue = !isAutoPlayEnabled

                userConfiguration.enableNextEpisodeAutoPlay = newValue
                mediaSession.userSession.user.data.configuration = userConfiguration
                viewModel.updateConfiguration(userConfiguration)

                if newValue {
                    toaster.present("Auto Play on", systemName: "play.circle.fill")
                } else {
                    toaster.present("Auto Play off", systemName: "stop.circle")
                }
            } label: {
                Label(
                    L10n.autoPlay,
                    systemImage: systemImage
                )

                if isInMenu {
                    Text(isAutoPlayEnabled ? "On" : "Off")
                }
            }
            .if(isInMenu && !viewLayout.isLarge) { button in
                button
                    .id(isAutoPlayEnabled)
            }
            .disabled(mediaSession.queue == nil)
        }
    }
}
