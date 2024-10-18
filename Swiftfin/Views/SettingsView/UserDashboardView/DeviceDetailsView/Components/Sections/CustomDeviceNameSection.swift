//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Enable for CustomNames for Devices with SDK Changes

extension DeviceDetailsView {
    struct CustomDeviceNameSection: View {
        @Binding
        var customName: String

        // MARK: - Body

        var body: some View {
            Section {
                TextField(
                    L10n.name,
                    text: $customName
                )
            } header: {
                Text(L10n.customDeviceName)
                // TODO: Remove Footer after SDK Changes
            } footer: {
                Text("This field will not reflect your custom device name on this version of Swiftin.")
            }
        }
    }
}
