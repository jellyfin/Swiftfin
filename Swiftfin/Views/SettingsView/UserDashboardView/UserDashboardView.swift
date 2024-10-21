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

            ListTitleSection(
                L10n.dashboard,
                description: L10n.dashboardDescription
            )

            ChevronButton(L10n.activeDevices)
                .onSelect {
                    router.route(to: \.activeSessions)
                }

            Section("Activity") {
                ChevronButton(L10n.devices)
                    .onSelect {
                        router.route(to: \.devices)
                    }
            }

            Section(L10n.advanced) {

                ChevronButton(L10n.logs)
                    .onSelect {
                        router.route(to: \.serverLogs)
                    }

                ChevronButton(L10n.tasks)
                    .onSelect {
                        router.route(to: \.tasks)
                    }
            }
        }
        .navigationTitle(L10n.dashboard)
    }
}
