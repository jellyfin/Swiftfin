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
    struct UserSection: View {
        var device: DeviceInfo

        var body: some View {
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
        }
    }
}
