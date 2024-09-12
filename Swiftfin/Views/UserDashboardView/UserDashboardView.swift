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
    @State
    private var showRestartConfirmation = false
    @State
    private var showShutdownConfirmation = false

    @StateObject
    private var serverViewModel: EditServerViewModel
    @StateObject
    private var sessionViewModel = ActiveSessionsViewModel()
    @StateObject
    private var functionsViewModel = ServerFunctionsViewModel()
    @StateObject
    private var currentUserViewModel = CurrentUserViewModel()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Init

    init(server: ServerState) {
        self._currentServerURL = State(initialValue: server.currentURL)
        self._serverViewModel = StateObject(wrappedValue: EditServerViewModel(server: server))
        self._sessionViewModel = StateObject(wrappedValue: ActiveSessionsViewModel())
    }

    // MARK: Grid Layout

    private var gridLayout: [GridItem] {
        let columns = UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
    }

    // MARK: Grid Layout

    private var currentUser: UserDto? {
        currentUserViewModel.user
    }

    // MARK: Body

    var body: some View {
        List {
            Section(header: Text(L10n.server)) {
                serverFunctions
            }

            // TODO: Hide this Section if the User is not an Administrator
            if currentUser?.policy?.isAdministrator ?? false {
                Section("Administration") {
                    adminFunctions
                }
            }

            Section(L10n.activeDevices) {
                activeDevices
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(L10n.dashboard)
        .onAppear {
            sessionViewModel.send(.refresh)
            currentUserViewModel.send(.load)
        }
        .onReceive(timer) { _ in
            sessionViewModel.send(.backgroundRefresh)
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

    // MARK: Admin Function buttons

    @ViewBuilder
    private var adminFunctions: some View {
        Button(action: {
            functionsViewModel.send(.scanLibrary)
        }) {
            Text("Scan All Libraries")
        }
        .foregroundColor(.primary)

        Button("Restart Server", role: .destructive) {
            showRestartConfirmation = true
        }
        .confirmationDialog(
            "Are you sure you want to restart the server?",
            isPresented: $showRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restart", role: .destructive) {
                functionsViewModel.send(.restartApplication)
            }
        }

        Button("Shutdown Server", role: .destructive) {
            showShutdownConfirmation = true
        }
        .confirmationDialog(
            "Are you sure you want to shutdown the server?",
            isPresented: $showShutdownConfirmation,
            titleVisibility: .visible
        ) {
            Button("Shutdown", role: .destructive) {
                functionsViewModel.send(.shutdownApplication)
            }
        }
    }

    // MARK: Active Devices

    @ViewBuilder
    private var activeDevices: some View {
        ScrollView {
            LazyVGrid(columns: gridLayout) {
                ForEach(orderedSessions) { session in
                    ActiveSessionButton(session: session) {
                        router.route(
                            to: \.activeDeviceDetails,
                            ActiveSessionsViewModel(deviceID: session.deviceID)
                        )
                    }
                    .padding(0)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Ordered Sessions

    private var orderedSessions: [SessionInfo] {
        sessionViewModel.sessions.sorted {
            let isPlaying0 = $0.nowPlayingItem != nil
            let isPlaying1 = $1.nowPlayingItem != nil

            if isPlaying0 && !isPlaying1 {
                return true
            } else if !isPlaying0 && isPlaying1 {
                return false
            }

            if $0.userName != $1.userName {
                return ($0.userName ?? "") < ($1.userName ?? "")
            }

            if isPlaying0 && isPlaying1 {
                return ($0.nowPlayingItem?.name ?? "") < ($1.nowPlayingItem?.name ?? "")
            } else {
                return ($0.lastActivityDate ?? Date.distantPast) > ($1.lastActivityDate ?? Date.distantPast)
            }
        }
    }
}
