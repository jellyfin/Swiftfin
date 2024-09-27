//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct UserDashboardView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    // MARK: - Body

    var body: some View {
        List {
            ChevronButton(L10n.activeDevices)
                .onSelect {
                    router.route(to: \.activeDevices)
                }

            ChevronButton(L10n.scheduledTasks)
                .onSelect {
                    router.route(to: \.scheduledTasks)
                }
        }
        .navigationTitle(L10n.dashboard)
    }
}
