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

    struct ManagementSection: View {

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section(L10n.management) {

                Toggle(
                    L10n.administrator,
                    isOn: $policy.isAdministrator.coalesce(false)
                )

                Toggle(
                    L10n.collections,
                    isOn: $policy.enableCollectionManagement
                )

                Toggle(
                    L10n.subtitles,
                    isOn: $policy.enableSubtitleManagement
                )

                Toggle(
                    L10n.lyrics,
                    isOn: $policy.enableLyricManagement
                )
            }
        }
    }
}
