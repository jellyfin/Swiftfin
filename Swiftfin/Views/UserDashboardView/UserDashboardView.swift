//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct UserDashboardView: View {
    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var currentServerURL: URL

    @StateObject
    private var serverViewModel: EditServerViewModel

    @StateObject
    private var sessionViewModel: ActiveSessionsViewModel

    init(server: ServerState) {
        self._currentServerURL = State(initialValue: server.currentURL)
        self._serverViewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
        self._sessionViewModel = StateObject(wrappedValue: ActiveSessionsViewModel())
    }

    var body: some View {
        NavigationView {
            List {
                Section(L10n.server) {
                    TextPairView(
                        leading: L10n.name,
                        trailing: serverViewModel.server.name
                    )

                    Picker(L10n.url, selection: $currentServerURL) {
                        ForEach(serverViewModel.server.urls.sorted(using: \.absoluteString)) { url in
                            Text(url.absoluteString)
                                .tag(url)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section(L10n.sessions) {
                    ChevronButton(L10n.activeDevices)
                        .onSelect {
                            router.route(to: \.activeSessions)
                        }
                }
            }
        }
        .navigationTitle(L10n.dashboard)
    }
}
