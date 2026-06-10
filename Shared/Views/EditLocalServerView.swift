//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditLocalServerView: View {

    @Router
    private var router

    @State
    private var isPresentingConfirmDeletion: Bool = false

    @StateObject
    private var viewModel: ServerConnectionViewModel

    private let isDeletePresented: Bool

    init(server: ServerState, isDeletePresented: Bool = false) {
        self._viewModel = StateObject(wrappedValue: ServerConnectionViewModel(server: server))
        self.isDeletePresented = isDeletePresented
    }

    var body: some View {
        Form(systemImage: "server.rack") {

            Section(L10n.server) {

                LabeledContent(
                    L10n.name,
                    value: viewModel.server.name
                )
                #if os(tvOS)
                .focusable(false)
                #endif

                if let serverVersion = StoredValues[.Server.publicInfo(id: viewModel.server.id)].version {
                    LabeledContent(
                        L10n.version,
                        value: serverVersion
                    )
                    #if os(tvOS)
                    .focusable(false)
                    #endif
                }
            }

            Section {
                ChevronButton(
                    L10n.connections,
                    content: viewModel.connections.count.description
                ) {
                    router.route(to: .serverConnections(viewModel: viewModel))
                }
            } footer: {
                if !viewModel.server.isVersionCompatible {
                    Label(
                        L10n.serverVersionWarning(viewModel.server.client.version.majorMinor.description),
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            if isDeletePresented {
                Section {
                    Button(L10n.delete, role: .destructive) {
                        isPresentingConfirmDeletion = true
                    }
                }
            }
        }
        .navigationTitle(L10n.server)
        .alert(L10n.deleteServer, isPresented: $isPresentingConfirmDeletion) {
            Button(L10n.delete, role: .destructive) {
                viewModel.delete()
                router.dismiss()
            }
        } message: {
            Text(L10n.confirmDeleteServerAndUsers(viewModel.server.name))
        }
    }
}
