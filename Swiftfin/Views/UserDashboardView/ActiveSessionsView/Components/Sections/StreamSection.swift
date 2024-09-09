//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {
    struct StreamSection: View {

        let client: String
        let deviceName: String
        let applicationVersion: String

        init(session: SessionInfo) {
            self.client = session.client ?? L10n.unknown
            self.deviceName = session.deviceName ?? L10n.unknown
            self.applicationVersion = session.applicationVersion ?? L10n.unknown
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Client:")
                    Spacer()
                    Text(client)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Device:")
                    Spacer()
                    Text(deviceName)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Version:")
                    Spacer()
                    Text(applicationVersion)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
