//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
    struct ButtonSection: View {

        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType

        @Default(.VideoPlayer.showJumpButtons)
        private var showJumpButtons

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons

        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled

        @EnvironmentObject
        private var router: VideoPlayerSettingsCoordinator.Router

        var body: some View {
            Section(L10n.buttons) {

                CaseIterablePicker(L10n.playbackButtons, selection: $playbackButtonType)

                Toggle(isOn: $showJumpButtons) {
                    HStack {
                        Image(systemName: "goforward")
                        Text(L10n.jump)
                    }
                }

                ChevronButton(L10n.barButtons)
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $barActionButtons)
                    }

                ChevronButton(L10n.menuButtons)
                    .onSelect {
                        router.route(to: \.actionButtonSelector, $menuActionButtons)
                    }
            }
            .onChange(of: barActionButtons) { newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || menuActionButtons.contains(.autoPlay)
            }
            .onChange(of: menuActionButtons) { newValue in
                autoPlayEnabled = newValue.contains(.autoPlay) || barActionButtons.contains(.autoPlay)
            }
        }
    }
}
