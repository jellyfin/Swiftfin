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

        @Environment(\.isEditing)
        var isEditing

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section("Media playback") {
                Toggle("Allow media playback", isOn: Binding(
                    get: { policy.enableMediaPlayback ?? false },
                    set: { policy.enableMediaPlayback = $0 }
                ))

                Toggle("Allow audio transcoding", isOn: Binding(
                    get: { policy.enableAudioPlaybackTranscoding ?? false },
                    set: { policy.enableAudioPlaybackTranscoding = $0 }
                ))

                Toggle("Allow video transcoding", isOn: Binding(
                    get: { policy.enableVideoPlaybackTranscoding ?? false },
                    set: { policy.enableVideoPlaybackTranscoding = $0 }
                ))

                Toggle("Allow video remuxing", isOn: Binding(
                    get: { policy.enablePlaybackRemuxing ?? false },
                    set: { policy.enablePlaybackRemuxing = $0 }
                ))

                Toggle("Force remote media transcoding", isOn: Binding(
                    get: { policy.isForceRemoteSourceTranscoding ?? false },
                    set: { policy.isForceRemoteSourceTranscoding = $0 }
                ))
            }
            .disabled(!isEditing)
        }
    }
}
