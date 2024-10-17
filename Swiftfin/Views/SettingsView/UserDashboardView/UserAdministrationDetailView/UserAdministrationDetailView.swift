//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct UserAdministrationDetailView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var observer: UserAdministrationObserver

    var body: some View {
        List {
            // TODO: Profile
            // TODO: Permissions
            // TODO: Access
            // TODO: Parental Controls

            ChevronButton(L10n.password)
                .onSelect {
                    router.route(to: \.userPassword, observer)
                }

            // TODO: Devices
        }
        .navigationTitle(observer.user.name ?? L10n.user)
    }
}
