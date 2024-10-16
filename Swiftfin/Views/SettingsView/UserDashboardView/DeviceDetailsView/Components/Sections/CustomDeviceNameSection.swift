//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Enable for CustomNames for Devices: 28, 52, & 55

extension DeviceDetailsView {
    struct CustomDeviceNameSection: View {
        var device: DeviceInfo

        @StateObject
        private var viewModel: DevicesViewModel

        @State
        private var temporaryCustomName: String

        // MARK: - Init

        init(device: DeviceInfo) {
            self.device = device
            self.temporaryCustomName = device.name ?? "" // device.customName ?? device.name
            _viewModel = StateObject(wrappedValue: DevicesViewModel(device.lastUserID))
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.customDeviceName) {
                ChevronAlertButton(
                    L10n.nickname,
                    subtitle: temporaryCustomName,
                    description: L10n.enterCustomDeviceName
                ) {
                    TextField(
                        L10n.name,
                        text: $temporaryCustomName
                    )
                } onSave: {
                    if let deviceID = device.id, temporaryCustomName != "" {
                        viewModel.send(.setCustomName(
                            id: deviceID,
                            newName: temporaryCustomName
                        ))
                    } else {
                        temporaryCustomName = device.name ?? "" // device.customName ?? device.name
                    }
                } onCancel: {
                    temporaryCustomName = device.name ?? "" // device.customName ?? device.name
                }
            }
        }
    }
}
