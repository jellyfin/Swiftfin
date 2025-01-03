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
    struct SubtitleSection: View {
        @Default(.VideoPlayer.Subtitle.subtitleFontName)
        private var subtitleFontName
        @Default(.VideoPlayer.Subtitle.subtitleSize)
        private var subtitleSize
        @Default(.VideoPlayer.Subtitle.subtitleColor)
        private var subtitleColor

        @EnvironmentObject
        private var router: VideoPlayerSettingsCoordinator.Router

        var body: some View {
            Section {
                ChevronButton(L10n.subtitleFont, subtitle: subtitleFontName)
                    .onSelect {
                        router.route(to: \.fontPicker, $subtitleFontName)
                    }

                BasicStepper(
                    title: L10n.subtitleSize,
                    value: $subtitleSize,
                    range: 1 ... 24,
                    step: 1
                )

                ColorPicker(selection: $subtitleColor, supportsOpacity: false) {
                    Text(L10n.subtitleColor)
                }
            } header: {
                Text(L10n.subtitle)
            } footer: {
                // TODO: better wording
                Text(L10n.subtitlesDisclaimer)
            }
        }
    }
}
