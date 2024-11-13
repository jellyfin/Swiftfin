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

    struct ExternalAccessSection: View {

        @Binding
        var maxBitratePolicy: MaxBitratePolicy
        @Binding
        var policy: UserPolicy

        // MARK: - Body

        var body: some View {
            Section(L10n.remoteConnections) {
                Toggle(L10n.allowRemoteConnections, isOn: Binding(
                    get: { policy.enableRemoteAccess ?? false },
                    set: { policy.enableRemoteAccess = $0 }
                ))

                Picker(L10n.maximumRemoteBitrate, selection: $maxBitratePolicy) {
                    ForEach(MaxBitratePolicy.allCases, id: \.self) { policy in
                        Text(policy.displayTitle).tag(policy)
                    }
                    .onChange(of: maxBitratePolicy) { newPolicy in
                        policy.remoteClientBitrateLimit = newPolicy.rawValue
                    }
                }

                if maxBitratePolicy == .custom {
                    ChevronAlertButton(
                        L10n.customBitrate,
                        subtitle: policy.remoteClientBitrateLimit?.formatted(.bitRate),
                        description: L10n.enterCustomBitrate
                    ) {
                        MaxBitrateDescription()
                    }
                }
            }
        }

        // MARK: - Create Bitrate Text

        @ViewBuilder
        private func MaxBitrateDescription() -> some View {
            let displayBitrate = Double(policy.remoteClientBitrateLimit ?? 0) / 1_000_000

            let bitrateBinding = Binding<Double>(
                get: { displayBitrate },
                set: { newValue in
                    policy.remoteClientBitrateLimit = Int(newValue * 1_000_000)
                }
            )

            TextField(L10n.maximumBitrate, value: bitrateBinding, format: .number)
                .keyboardType(.numbersAndPunctuation)
        }
    }
}
