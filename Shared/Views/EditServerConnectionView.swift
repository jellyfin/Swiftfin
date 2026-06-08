//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditServerConnectionView: View {

    @ObservedObject
    var viewModel: ServerConnectionViewModel

    @Router
    private var router

    @State
    private var draft: ServerConnectionDraft

    @Toaster
    private var toaster

    private let initialConnection: ServerConnection
    private let initialDraft: ServerConnectionDraft

    private var storedConnection: ServerConnection? {
        viewModel.connections.first { $0.id == initialConnection.id }
    }

    private var connection: ServerConnection {
        storedConnection ?? initialConnection
    }

    private var isExistingConnection: Bool {
        storedConnection != nil
    }

    private var testState: ServerConnectionTestState {
        viewModel.testStates[initialConnection.id] ?? .idle
    }

    private var isTesting: Bool {
        if case .testing = testState {
            true
        } else {
            false
        }
    }

    private var isCurrentConnection: Bool {
        viewModel.activeConnection?.id == initialConnection.id
    }

    private var hasChanges: Bool {
        draft != initialDraft
    }

    init(
        viewModel: ServerConnectionViewModel,
        connection: ServerConnection
    ) {
        self.viewModel = viewModel
        self.initialConnection = connection
        self.initialDraft = ServerConnectionDraft(connection: connection)

        self._draft = State(initialValue: ServerConnectionDraft(connection: connection))
    }

    var body: some View {
        Form(systemImage: "network") {
            Section(L10n.name) {
                TextField(L10n.name, text: $draft.name)
            }

            Section(L10n.serverURL) {
                TextField(L10n.serverURL, text: $draft.urlString)
                #if !os(tvOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                #endif
            }

            Section(L10n.network) {
                Picker(L10n.network, selection: $draft.interface) {
                    ForEach(ServerConnectionInterface.allCases, id: \.self) { interface in
                        Label(interface.displayTitle, systemImage: interface.systemImage)
                            .tag(interface)
                    }
                }

                if draft.interface == .wifi {
                    Toggle(L10n.specificNetwork, isOn: $draft.isSpecificWifiNetwork)

                    if draft.isSpecificWifiNetwork {
                        TextField(L10n.wifiName, text: $draft.wifiSSID)
                        #if !os(tvOS)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        #endif
                    }
                }
            }

            Section(L10n.enabled) {
                Toggle(L10n.enabled, isOn: $draft.isEnabled)
            }

            Section(L10n.status) {
                if isCurrentConnection {
                    Label(L10n.active, systemImage: "circle.fill")
                        .foregroundStyle(.green)
                } else if isExistingConnection {
                    Button(L10n.use) {
                        setActiveConnection(connection)
                    }
                    .disabled(!connection.isEnabled || isTesting || hasChanges)
                }

                Button(L10n.test) {
                    testDraft()
                }
                .disabled(isTesting)

                testStatusView
            }
            
            Section {
                if isExistingConnection {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.deleteConnection(connection)
                        router.dismiss()
                    }
                    .disabled(viewModel.connections.count <= 1 || isCurrentConnection)
                }
            }
        }
        .navigationTitle(isExistingConnection ? L10n.connection : L10n.newConnection)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            Button(L10n.save) {
                Task { await save() }
            }
            .disabled(isTesting || !hasChanges)
            #if os(iOS)
                .buttonStyle(.toolbarPill)
            #endif
        }
        .animation(.linear(duration: 0.1), value: draft.interface)
        .animation(.linear(duration: 0.1), value: draft.isSpecificWifiNetwork)
        .backport
        .onChange(of: draft.interface) { _, newValue in
            guard newValue == .wifi, draft.wifiSSID.nilIfBlank == nil else { return }
            populateCurrentWifiSSID(keepSpecificOnFailure: false)
        }
        .backport
        .onChange(of: draft.isSpecificWifiNetwork) { _, newValue in
            guard newValue, draft.interface == .wifi, draft.wifiSSID.nilIfBlank == nil else { return }
            populateCurrentWifiSSID(keepSpecificOnFailure: true)
        }
    }

    @ViewBuilder
    private var testStatusView: some View {
        switch testState {
        case .idle:
            EmptyView()
        case .testing:
            Label(L10n.test, systemImage: "hourglass")
                .foregroundStyle(.secondary)
        case let .success(version):
            Label(L10n.connectedTo(version), systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case let .failure(message):
            Label(message.nilIfBlank ?? L10n.connectionFailed, systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        }
    }

    private func save() async {
        if let validationError = draft.validationError {
            toaster.present(validationError, systemName: "exclamationmark.circle.fill")
            return
        }

        guard let connection = draft.connection() else {
            toaster.present(L10n.invalidURL, systemName: "exclamationmark.circle.fill")
            return
        }

        let state = await viewModel.saveConnection(connection)
        guard case .success = state else { return }

        toaster.present(L10n.connectionSaved, systemName: "checkmark.circle.fill")
        router.dismiss()
    }

    private func setActiveConnection(_ connection: ServerConnection) {
        Task {
            let state = await viewModel.setActiveConnectionIfValid(connection)

            switch state {
            case .idle, .testing, .success:
                break
            case .failure:
                toaster.present(L10n.connectionFailed, systemName: "xmark.circle.fill")
            }
        }
    }

    private func testDraft() {
        if let validationError = draft.validationError {
            toaster.present(validationError, systemName: "exclamationmark.circle.fill")
            return
        }

        guard let draftConnection = draft.connection() else {
            toaster.present(L10n.invalidURL, systemName: "exclamationmark.circle.fill")
            return
        }

        test(draftConnection)
    }

    private func populateCurrentWifiSSID(keepSpecificOnFailure: Bool) {
        Task { @MainActor in
            guard let ssid = await NetworkConnectionContext.currentWifiSSID() else {
                draft.isSpecificWifiNetwork = keepSpecificOnFailure
                return
            }

            draft.wifiSSID = ssid
            draft.isSpecificWifiNetwork = true
        }
    }

    private func test(_ connection: ServerConnection) {
        Task {
            let state = await viewModel.testConnection(connection)

            switch state {
            case .idle, .testing:
                break
            case let .success(version):
                toaster.present(L10n.connectedTo(version), systemName: "checkmark.circle.fill")
            case .failure:
                toaster.present(L10n.connectionFailed, systemName: "xmark.circle.fill")
            }
        }
    }
}

private struct ServerConnectionDraft: Equatable {
    let id: String
    var name: String
    var urlString: String
    var interface: ServerConnectionInterface
    var wifiSSID: String
    var priority: Int
    var isEnabled: Bool
    var isSpecificWifiNetwork: Bool

    init(connection: ServerConnection) {
        self.id = connection.id
        self.name = connection.name
        self.urlString = connection.url.absoluteString
        self.interface = connection.interface
        self.wifiSSID = connection.wifiSSID
        self.priority = connection.priority
        self.isEnabled = connection.isEnabled
        self.isSpecificWifiNetwork = connection.interface == .wifi && connection.wifiSSID.nilIfBlank != nil
    }

    var formattedURL: URL? {
        let formattedURL = urlString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prepending("http://", if: !urlString.contains("://"))

        return URL(string: formattedURL)
    }

    var validationError: String? {
        guard formattedURL != nil else { return L10n.invalidURL }

        let normalizedSSID = wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
        if interface == .wifi, isSpecificWifiNetwork, normalizedSSID.nilIfBlank == nil {
            return L10n.invalidX(L10n.wifiName)
        }

        return nil
    }

    func connection() -> ServerConnection? {
        let normalizedSSID = wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validationError == nil, let url = formattedURL else { return nil }

        return ServerConnection(
            id: id,
            name: name,
            url: url,
            interface: interface,
            wifiSSID: interface == .wifi && isSpecificWifiNetwork ? normalizedSSID : .empty,
            priority: priority,
            isEnabled: isEnabled
        )
    }
}
