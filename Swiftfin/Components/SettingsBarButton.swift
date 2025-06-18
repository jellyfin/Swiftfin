//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct SettingsBarButton: View {

    let server: ServerState
    let user: UserState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AlternateLayoutView {
                // Seems necessary for button layout
                Image(systemName: "gearshape.fill")
            } content: {
                UserProfileImage(
                    userID: user.id,
                    source: user.profileImageSource(
                        client: server.client,
                        maxWidth: 120
                    ),
                    pipeline: .Swiftfin.local
                )
            }
        }
        .accessibilityLabel(L10n.settings)
    }
}
