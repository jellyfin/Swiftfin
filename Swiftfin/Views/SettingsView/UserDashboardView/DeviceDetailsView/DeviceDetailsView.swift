//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct DeviceDetailsView: View {
    var device: DeviceInfo

    var body: some View {
        List {
            UserSection(device: device)

            CustomDeviceNameSection(device: device)

            DeviceSection(device: device)

            CapabilitiesSection(device: device)
        }
        .navigationTitle(L10n.device)
    }
}
