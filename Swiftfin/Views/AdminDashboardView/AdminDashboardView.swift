//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AdminDashboardView: View {

    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    // MARK: - Body

    var body: some View {
        List {

            ListTitleSection(
                L10n.dashboard,
                description: L10n.dashboardDescription
            )

            ChevronButton(L10n.sessions)
                .onSelect {
                    router.route(to: \.activeSessions)
                }

            Section(L10n.activity) {
                ChevronButton(L10n.devices)
                    .onSelect {
                        router.route(to: \.devices)
                    }
                ChevronButton(L10n.users)
                    .onSelect {
                        router.route(to: \.users)
                    }
            }

            Section(L10n.advanced) {

                ChevronButton(L10n.apiKeys)
                    .onSelect {
                        router.route(to: \.apiKeys)
                    }

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
        .navigationBarTitleDisplayMode(.inline)
    }
}
