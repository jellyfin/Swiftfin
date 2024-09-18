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

struct UserDashboardView: View {
    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var currentServerURL: URL

    @StateObject
    private var serverViewModel: EditServerViewModel
    @StateObject
    private var currentUserViewModel = CurrentUserViewModel()
    @StateObject
    private var sessionsViewModel = ActiveSessionsViewModel()

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    // MARK: Init

    init(server: ServerState) {
        self._currentServerURL = State(initialValue: server.currentURL)
        self._serverViewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
        self._sessionsViewModel = StateObject(wrappedValue: ActiveSessionsViewModel())
    }

    // MARK: Grid Layout

    private var gridLayout: [GridItem] {
        let columns = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }

    // MARK: Current User

    private var currentUser: UserDto? {
        currentUserViewModel.user
    }

    // MARK: Body

    var body: some View {
        List {
            Section(header: Text(L10n.server)) {
                serverFunctions
            }

            // Only Show Admin Functions if the user has the isAdministrator Policy
            if currentUser?.policy?.isAdministrator ?? false {
                ChevronButton(L10n.scheduledTasks)
                    .onSelect {
                        router.route(to: \.scheduledTasks)
                    }
            }

            ChevronButton(
                L10n.activeDevices,
                subtitle: sessionsViewModel.sessions.count.description
            )
            .onSelect {
                router.route(to: \.activeDevices)
            }
        }
        .navigationTitle(L10n.dashboard)
        .onAppear {
            currentUserViewModel.send(.fetchUser)
            sessionsViewModel.send(.refresh)
        }
    }

    // MARK: Server Name & URL Switching

    @ViewBuilder
    private var serverFunctions: some View {
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
}
