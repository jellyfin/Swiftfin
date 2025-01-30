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

    struct RemoteControlSection: View {

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section(L10n.remoteControl) {

                Toggle(
                    L10n.controlOtherUsers,
                    isOn: $policy.enableRemoteControlOfOtherUsers.coalesce(false)
                )

                Toggle(
                    L10n.controlSharedDevices,
                    isOn: $policy.enableSharedDeviceControl.coalesce(false)
                )
            }
        }
    }
}
