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
    struct ResumeOffsetSection: View {
        @Default(.VideoPlayer.resumeOffset)
        private var resumeOffset

        @EnvironmentObject
        private var router: VideoPlayerSettingsCoordinator.Router

        var body: some View {
            Section {
                ChevronButton(
                    L10n.offset,
                    subtitle: resumeOffset.secondLabel
                )
                .onSelect {
                    router.route(to: \.resumeOffset, $resumeOffset)
                }
            } header: {
                L10n.resume.text
            } footer: {
                L10n.resumeOffsetDescription.text
            }
        }
    }
}
