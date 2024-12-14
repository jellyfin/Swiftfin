//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension SelectUserView {

    struct ServerSelectionMenu: View {

        @EnvironmentObject
        private var router: SelectUserCoordinator.Router

        @Binding
        private var serverSelection: SelectUserServerSelection

        @ObservedObject
        private var viewModel: SelectUserViewModel

        @State
        private var isPresentingServers: Bool = false

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
            Button {
                let parameters = SelectUserCoordinator.SelectServerParameters(
                    selection: _serverSelection,
                    viewModel: viewModel
                )

                router.route(to: \.selectServer, parameters)
            } label: {
                ZStack {

                    Group {
                        switch serverSelection {
                        case .all:
                            Label(L10n.allServers, systemImage: "person.2.fill")
                        case let .server(id):
                            if let server = viewModel.servers.keys.first(where: { $0.id == id }) {
                                Label(server.name, systemImage: "server.rack")
                            }
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.primary)
                }
                .frame(height: 50)
                .frame(maxWidth: 400)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
