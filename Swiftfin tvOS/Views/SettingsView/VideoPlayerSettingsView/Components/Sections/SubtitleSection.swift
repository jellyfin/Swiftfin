//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayerSettingsView {
    struct SubtitleSection: View {
        @Default(.VideoPlayer.Subtitle.subtitleFontName)
        private var subtitleFontName
        @Default(.VideoPlayer.Subtitle.subtitleSize)
        private var subtitleSize

        @EnvironmentObject
        private var router: VideoPlayerSettingsCoordinator.Router

        var body: some View {
            Section {
                ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName)
                    .onSelect {
                        router.route(to: \.fontPicker, $subtitleFontName)
                    }

                ChevronButton(
                    L10n.subtitleSize,
                    subtitle: subtitleSize.description
                )
                .onSelect {
                    router.route(to: \.subtitleSize, $subtitleSize)
                }
            } header: {
                L10n.subtitle.text
            } footer: {
                L10n.subtitleDescription.text
            }
        }
    }
}
