//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct MediaPlaybackSection: View {

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section(L10n.mediaPlayback) {

                Toggle(
                    L10n.mediaPlayback,
                    isOn: $policy.enableMediaPlayback.coalesce(false)
                )

                Toggle(
                    L10n.audioTranscoding,
                    isOn: $policy.enableAudioPlaybackTranscoding.coalesce(false)
                )

                Toggle(
                    L10n.videoTranscoding,
                    isOn: $policy.enableVideoPlaybackTranscoding.coalesce(false)
                )

                Toggle(
                    L10n.videoRemuxing,
                    isOn: $policy.enablePlaybackRemuxing.coalesce(false)
                )

                Toggle(
                    L10n.forceRemoteTranscoding,
                    isOn: $policy.isForceRemoteSourceTranscoding.coalesce(false)
                )
            }
        }
    }
}
