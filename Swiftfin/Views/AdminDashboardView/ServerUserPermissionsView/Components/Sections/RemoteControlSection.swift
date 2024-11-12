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

    struct RemoteControlSection: View {

        @Environment(\.isEditing)
        var isEditing

        @Binding
        var policy: UserPolicy

        var body: some View {
            Section("Remote control") {
                Toggle("Control other users", isOn: Binding(
                    get: { policy.enableRemoteControlOfOtherUsers ?? false },
                    set: { policy.enableRemoteControlOfOtherUsers = $0 }
                ))

                Toggle("Control shared devices", isOn: Binding(
                    get: { policy.enableSharedDeviceControl ?? false },
                    set: { policy.enableSharedDeviceControl = $0 }
                ))
            }
            .disabled(!isEditing)
        }
    }
}
