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
                Toggle(L10n.autoSwitchURLs, isOn: $viewModel.isAutoSwitchingEnabled)

                ForEach(viewModel.connections) { connection in
                    serverConnectionRow(connection)
                }
                .onMove(perform: viewModel.moveConnections)

                Button {
                    let connection = viewModel.newConnection()
                    router.route(to: editConnectionRoute(connection))
                } label: {
                    Label(L10n.addConnection, systemImage: "plus.circle.fill")
                }
            } header: {
                Text(L10n.connections)
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

    private func serverConnectionRow(_ connection: ServerConnection) -> some View {
        ChevronButton {
            router.route(to: editConnectionRoute(connection))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.displayName)
                        .font(.headline)

                    Text(connection.url.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if connection.interface == .wifi {
                        Text(connection.normalizedSSID ?? L10n.anyWifiNetwork)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.activeConnection?.id == connection.id {
                    Spacer()

                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private func editConnectionRoute(_ connection: ServerConnection) -> NavigationRoute {
        NavigationRoute(
            id: "serverConnection-\(viewModel.server.id)-\(connection.id)",
            style: .sheet
        ) {
            EditServerConnectionView(
                viewModel: viewModel,
                connection: connection
            )
        }
    }
}
