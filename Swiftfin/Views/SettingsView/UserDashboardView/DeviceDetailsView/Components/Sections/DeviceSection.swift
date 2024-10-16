//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension DeviceDetailsView {
    struct DeviceSection: View {
        var device: DeviceInfo

        var body: some View {
            Section(L10n.device) {
                if let deviceName = device.name {
                    TextPairView(leading: L10n.name, trailing: deviceName)
                }

                if let client = device.appName {
                    TextPairView(leading: L10n.client, trailing: client)
                }

                if let applicationVersion = device.appVersion {
                    TextPairView(leading: L10n.version, trailing: applicationVersion)
                }
            }
        }
    }
}
