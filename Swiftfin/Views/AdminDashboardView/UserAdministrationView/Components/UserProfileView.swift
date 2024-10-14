//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import SwiftUI

extension UserAdministrationView {

    struct UserProfileImage: View {

        @Injected(\.currentUserSession)
        private var userSession: UserSession!

        @ObservedObject
        var observer: UserAdministrationObserver

        @ViewBuilder
        var body: some View {
            ImageView(observer.user.profileImageSource(client: userSession.client))
                .pipeline(.Swiftfin.branding)
                .placeholder { _ in
                    SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                }
                .failure {
                    SystemImageContentView(systemName: "person.fill", ratio: 0.5)
                }
        }
    }
}
