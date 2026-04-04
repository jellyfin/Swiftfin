//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct AutoPlay: View {

        @Environment(\.isInMenu)
        private var isInMenu

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @StateObject
        private var viewModel: ServerUserAdminViewModel

        @State
        private var userConfiguration: UserConfiguration

        private var isAutoPlayEnabled: Bool {
            manager.userSession.user.data.configuration?.enableNextEpisodeAutoPlay == true
        }

        private var systemImage: String {
            if isAutoPlayEnabled {
                "play.circle.fill"
            } else {
                "stop.circle"
            }
        }

        init() {
            /// If there is no User or UserSession, updating the user on the server has the potential of nuking all settings.
            /// - Force Unwrap might crash but this is to prevent malformed UserDTO updating over real UserDTOs
            let user = Container.shared.currentUserSession()!.user.data

            self.userConfiguration = user.configuration!
            self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        }

        var body: some View {
            Button {
                let newValue = !isAutoPlayEnabled

                userConfiguration.enableNextEpisodeAutoPlay = newValue
                manager.userSession.user.data.configuration = userConfiguration
                viewModel.updateConfiguration(userConfiguration)
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
