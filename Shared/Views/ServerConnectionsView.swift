//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ServerConnectionsView: View {

    @ObservedObject
    var viewModel: ServerConnectionViewModel

    @Router
    private var router

    @State
    private var editMode: EditMode = .inactive

    @Default(.Experimental.serverConnectionAutoSwitch)
    private var isAutoSwitchFeatureEnabled

    private var isEditing: Bool {
        editMode.isEditing
    }

    @ViewBuilder
    private func serverConnectionRow(_ connection: ServerConnection) -> some View {
        Button {
            guard !isEditing else { return }
            router.route(to: .editServerConnection(viewModel: viewModel, connection: connection))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(connection.displayName)

                    Text(connection.url.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if connection.interface == .wifi {
                        Text(connection.normalizedSSID ?? L10n.anyWifiNetwork)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if viewModel.activeConnection?.id == connection.id {
                    Image(systemName: "circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if !isEditing {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .foregroundStyle(.primary, .secondary)
    }

    var body: some View {
        Form(systemImage: "network") {
            if isAutoSwitchFeatureEnabled {
                Section {
                    Toggle(L10n.autoSwitch, isOn: $viewModel.isAutoSwitchEnabled)

                    if viewModel.isAutoSwitchEnabled {
                        Button {
                            Task {
                                await viewModel.evaluateAutoSwitchConnection()
                            }
                        } label: {
                            HStack {
                                Text(L10n.evaluate)

                                Spacer()

                                if viewModel.isEvaluatingAutoSwitchConnection {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(viewModel.isEvaluatingAutoSwitchConnection)
                    }
                } footer: {
                    Text(L10n.autoSwitchDescription)
                }
                .disabled(isEditing)
            }

            Section(L10n.connections) {
                ForEach(viewModel.connections) { connection in
                    serverConnectionRow(connection)
                }
                .onMove(perform: viewModel.moveConnections)

                Button(L10n.add) {
                    router.route(
                        to: .editServerConnection(
                            viewModel: viewModel,
                            connection: viewModel.newConnection()
                        )
                    )
                }
                .disabled(isEditing)
            }
        }
        .environment(\.editMode, $editMode)
        .animation(.linear(duration: 0.1), value: isEditing)
        .animation(.linear(duration: 0.1), value: viewModel.connections)
        .animation(.linear(duration: 0.1), value: viewModel.isAutoSwitchEnabled)
        .navigationTitle(L10n.connections)
        .topBarTrailing {
            if viewModel.connections.count > 1 {
                Button(isEditing ? L10n.done : L10n.edit) {
                    editMode = isEditing ? .inactive : .active
                }
                #if os(iOS)
                .buttonStyle(.toolbarPill)
                #endif
            }
        }
    }
}
