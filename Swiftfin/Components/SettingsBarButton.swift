//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct SettingsBarButton: View {

    @Injected(\.currentUserSession)
    private var userSession

    @Router
    private var router

    var body: some View {
        Button {
            router.route(to: .settings)
        } label: {
            AlternateLayoutView {
                // Seems necessary for button layout
                Image(systemName: "gearshape.fill")
            } content: {

                let imageSource: ImageSource = {
                    guard let user = userSession?.user, let server = userSession?.server else {
                        return .init()
                    }

                    return user.profileImageSource(
                        client: server.client
                    )
                }()

                UserProfileImage(
                    userID: userSession?.user.id,
                    source: imageSource,
                    pipeline: .Swiftfin.local
                )
            }
        }
        .accessibilityLabel(L10n.settings)
    }
}
