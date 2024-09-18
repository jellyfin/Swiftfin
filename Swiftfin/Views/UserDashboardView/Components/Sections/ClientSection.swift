//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension UserDashboardView {
    struct ClientSection: View {
        let client: String?
        let deviceName: String?
        let applicationVersion: String?

        // MARK: Body

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.clientWithString(""))
                    Spacer()
                    Text(client ?? L10n.unknown)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(L10n.deviceWithString(""))
                    Spacer()
                    Text(deviceName ?? L10n.unknown)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(L10n.versionWithString(""))
                    Spacer()
                    Text(applicationVersion ?? L10n.unknown)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
