//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ServerUserPermissionsView {

    struct MediaPlaybackSection: View {

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section(L10n.mediaPlayback) {
                Toggle(L10n.mediaPlayback, isOn: Binding(
                    get: { policy.enableMediaPlayback ?? false },
                    set: { policy.enableMediaPlayback = $0 }
                ))

                Toggle(L10n.audioTranscoding, isOn: Binding(
                    get: { policy.enableAudioPlaybackTranscoding ?? false },
                    set: { policy.enableAudioPlaybackTranscoding = $0 }
                ))

                Toggle(L10n.videoTranscoding, isOn: Binding(
                    get: { policy.enableVideoPlaybackTranscoding ?? false },
                    set: { policy.enableVideoPlaybackTranscoding = $0 }
                ))

                Toggle(L10n.videoRemuxing, isOn: Binding(
                    get: { policy.enablePlaybackRemuxing ?? false },
                    set: { policy.enablePlaybackRemuxing = $0 }
                ))

                Toggle(L10n.forceRemoteTranscoding, isOn: Binding(
                    get: { policy.isForceRemoteSourceTranscoding ?? false },
                    set: { policy.isForceRemoteSourceTranscoding = $0 }
                ))
            }
        }
    }
}
