//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AdminDashboardView: View {

    @Router
    private var router

    var body: some View {
        List {

            ListTitleSection(
                L10n.dashboard,
                description: L10n.dashboardDescription
            )

            Section {
                ChevronButton(L10n.sessions) {
                    router.route(to: .activeSessions)
                }
            }

            Section(L10n.settings) {
                ChevronButton(L10n.general) {
                    router.route(to: .serverGeneral)
                }

                // TODO: Settings for Libraries
                // - Poster, Folders, Metadata Languagages, Etc.
                // ChevronButton(L10n.libraries) {
                //     router.route(to: .serverLibraries)
                // }

                // TODO: Settings for Playback
                // - Resume %, Remote Bitrate, Etc.
                // ChevronButton(L10n.playback) {
                //     router.route(to: .serverPlayback)
                // }
            }

            Section(L10n.activity) {
                ChevronButton(L10n.activity) {
                    router.route(to: .activity)
                }
                ChevronButton(L10n.devices) {
                    router.route(to: .devices)
                }
                ChevronButton(L10n.users) {
                    router.route(to: .users)
                }
            }

            Section(L10n.advanced) {
                ChevronButton(L10n.apiKeys) {
                    router.route(to: .apiKeys)
                }
                ChevronButton(L10n.logs) {
                    router.route(to: .serverLogs)
                }
                ChevronButton(L10n.tasks) {
                    router.route(to: .tasks)
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.dashboard)
    }
}
