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

struct UserDetailsView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @CurrentDate
    private var currentDate: Date

    @StateObject
    var observer: UserObserver

    // MARK: - Body

    var body: some View {
        List {
            if let userID = observer.user.id,
               let userName = observer.user.name
            {
                UserDashboardView.UserSection(
                    user: .init(id: userID, name: userName),
                    lastActivityDate: observer.user.lastActivityDate
                )
            }

            ChevronButton(L10n.devices)
                .onSelect {
                    if let userID = observer.user.id {
                        router.route(to: \.userDevices, userID)
                    }
                }
        }
        .navigationTitle(L10n.user)
        .onAppear {
            observer.send(.loadDetails)
        }
    }
}
