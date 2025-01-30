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

    struct ExternalAccessSection: View {

        @Binding
        var policy: UserPolicy

        // MARK: - Body

        var body: some View {
            Section(L10n.remoteConnections) {

                Toggle(
                    L10n.remoteConnections,
                    isOn: $policy.enableRemoteAccess.coalesce(false)
                )

                CaseIterablePicker(
                    L10n.maximumRemoteBitrate,
                    selection: $policy.remoteClientBitrateLimit.map(
                        getter: { MaxBitratePolicy(rawValue: $0) ?? .custom },
                        setter: { $0.rawValue }
                    )
                )

                if policy.remoteClientBitrateLimit != MaxBitratePolicy.unlimited.rawValue {
                    ChevronAlertButton(
                        L10n.customBitrate,
                        subtitle: Text(policy.remoteClientBitrateLimit ?? 0, format: .bitRate),
                        description: L10n.enterCustomBitrate
                    ) {
                        MaxBitrateInput()
                    }
                }
            }
        }

        // MARK: - Create Bitrate Input

        @ViewBuilder
        private func MaxBitrateInput() -> some View {
            let bitrateBinding = $policy.remoteClientBitrateLimit
                .coalesce(0)
                .map(
                    // Convert to Mbps
                    getter: { Double($0) / 1_000_000 },
                    setter: { Int($0 * 1_000_000) }
                )
                .min(0.001) // Minimum bitrate of 1 Kbps

            TextField(L10n.maximumBitrate, value: bitrateBinding, format: .number)
                .keyboardType(.numbersAndPunctuation)
        }
    }
}
