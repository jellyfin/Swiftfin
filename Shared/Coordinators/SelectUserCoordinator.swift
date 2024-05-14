//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class SelectUserCoordinator: NavigationCoordinatable {

    struct SelectServerParameters {
        let selection: Binding<SelectUserServerSelection>
        let viewModel: SelectUserViewModel
    }

    let stack = NavigationStack(initial: \SelectUserCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var advancedSettings = makeAdvancedSettings
    @Route(.modal)
    var connectToServer = makeConnectToServer
    @Route(.modal)
    var editServer = makeEditServer
    @Route(.modal)
    var userSignIn = makeUserSignIn

    #if os(tvOS)
    @Route(.fullScreen)
    var selectServer = makeSelectServer
    #endif

    func makeAdvancedSettings() -> NavigationViewCoordinator<AppSettingsCoordinator> {
        NavigationViewCoordinator(AppSettingsCoordinator())
    }

    func makeConnectToServer() -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ConnectToServerView()
        }
    }

    func makeEditServer(server: ServerState) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            EditServerView(server: server)
            #if os(iOS)
                .environment(\.isEditing, true)
                .navigationBarCloseButton {
                    self.popLast()
                }
            #endif
        }
    }

    func makeUserSignIn(server: ServerState) -> NavigationViewCoordinator<UserSignInCoordinator> {
        NavigationViewCoordinator(UserSignInCoordinator(server: server))
    }

    #if os(tvOS)
    func makeSelectServer(parameters: SelectServerParameters) -> some View {
        SelectServerView(
            selection: parameters.selection,
            viewModel: parameters.viewModel
        )
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        SelectUserView()
    }
}

struct SelectServerView: View {

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @Binding
    private var serverSelection: SelectUserServerSelection

    @ObservedObject
    private var viewModel: SelectUserViewModel

    private var selectedServer: ServerState? {
        if case let SelectUserServerSelection.server(id: id) = serverSelection,
           let server = viewModel.servers.keys.first(where: { server in server.id == id })
        {
            return server
        }

        return nil
    }

    init(
        selection: Binding<SelectUserServerSelection>,
        viewModel: SelectUserViewModel
    ) {
        self._serverSelection = selection
        self.viewModel = viewModel
    }

    var body: some View {
        FullScreenMenu("Servers") {
            Section {
                Button("Add Server", systemImage: "plus") {
                    router.popLast {
                        router.route(to: \.connectToServer)
                    }
                }

                if let selectedServer {
                    Button("Edit Server", systemImage: "server.rack") {
                        router.popLast {
                            router.route(to: \.editServer, selectedServer)
                        }
                    }
                }
            }

            Section {
//                        Picker("Servers", selection: _serverSelection) {

                if viewModel.servers.keys.count > 1 {
                    Label("All Servers", systemImage: "person.2.fill")
                        .tag(SelectUserServerSelection.all)
                }

                ForEach(viewModel.servers.keys.reversed()) { server in
                    Button {
                        VStack(alignment: .leading) {
                            Text(server.name)

                            Text(server.currentURL.absoluteString)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(SelectUserServerSelection.server(id: server.id))
                }
//                        }
            } header: {
                Text("Servers")
            }
            .headerProminence(.increased)
        }
    }
}
