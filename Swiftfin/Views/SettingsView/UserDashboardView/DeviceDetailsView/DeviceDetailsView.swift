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

// TODO: Enable for CustomNames for Devices: 31, 61, 75, 78

struct DeviceDetailsView: View {
    @State
    private var isPresentingRenameAlert = false
    @State
    private var temporaryCustomName: String
    @State
    private var selectedDevice: DeviceInfo?

    private var viewModel = DevicesViewModel()

    var device: DeviceInfo

    // MARK: - Body

    init(device: DeviceInfo) {
        self.device = device
        self.temporaryCustomName = device.name ?? "" // device.customName ?? device.name
    }

    // MARK: - Body

    var body: some View {
        List {
            // User Section
            Section(header: Text(L10n.user)) {
                if let userID = device.lastUserID {
                    SettingsView.UserProfileRow(
                        user: .init(
                            id: userID,
                            name: device.lastUserName
                        )
                    )
                }
                if let lastActivityDate = device.dateLastActivity {
                    TextPairView(
                        L10n.lastSeen,
                        value: Text(lastActivityDate, style: .date)
                    )
                    .monospacedDigit()
                }
            }

            // Custom Device Name Section
            Section(L10n.customDeviceName) {
                ChevronAlertButton(
                    L10n.nickname,
                    subtitle: temporaryCustomName, // device.customName ?? "",
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

            // Device Details Section
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

            // Client Capabilities Section
            Section(header: Text(L10n.capabilities)) {
                if let supportsContentUploading = device.capabilities?.isSupportsContentUploading {
                    TextPairView(leading: L10n.supportsContentUploading, trailing: supportsContentUploading ? L10n.yes : L10n.no)
                }

                if let supportsMediaControl = device.capabilities?.isSupportsMediaControl {
                    TextPairView(leading: L10n.supportsMediaControl, trailing: supportsMediaControl ? L10n.yes : L10n.no)
                }

                if let supportsPersistentIdentifier = device.capabilities?.isSupportsPersistentIdentifier {
                    TextPairView(leading: L10n.supportsPersistentIdentifier, trailing: supportsPersistentIdentifier ? L10n.yes : L10n.no)
                }

                if let supportsSync = device.capabilities?.isSupportsSync {
                    TextPairView(leading: L10n.supportsSync, trailing: supportsSync ? L10n.yes : L10n.no)
                }
            }
            .navigationTitle(L10n.device)
        }
    }
}
