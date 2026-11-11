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

        @StateObject
        private var viewModel: ServerUserAdminViewModel

        @Toaster
        private var toaster

        private var isAutoPlayEnabled: Bool {
            mediaSession.userSession.userData.configuration?.enableNextEpisodeAutoPlay == true
        }

        private var systemImage: String {
            if isAutoPlayEnabled {
                VideoPlayerActionButton.autoPlay.systemImage
            } else {
                VideoPlayerActionButton.autoPlay.secondarySystemImage
            }
        }

        init() {
            let user = Container.shared.currentUserSession()?.userData ?? UserDto()

            self._viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
        }

        @ContentBuilder
        var body: some View {
            Button {
                let newValue = !isAutoPlayEnabled

                var userConfiguration = viewModel.user.configuration ?? UserConfiguration()
                userConfiguration.enableNextEpisodeAutoPlay = newValue
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
            .if(isInMenu && !viewLayout.isLarge) { button in
                button
                    .id(isAutoPlayEnabled)
            }
            .disabled(mediaSession.queue == nil || viewModel.background.is(.updating))
            .errorMessage($viewModel.error)
            .onReceive(viewModel.events) { _ in
                if isAutoPlayEnabled {
                    toaster.present("Auto Play on", systemName: "play.circle.fill")
                } else {
                    toaster.present("Auto Play off", systemName: "stop.circle")
                }
            }
        }
    }
}
