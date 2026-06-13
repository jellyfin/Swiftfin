//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EditServerConnectionView: View {

    @FocusState
    private var isNameFocused: Bool

    @ObservedObject
    var viewModel: ServerConnectionViewModel

    @Router
    private var router

    @State
    private var draft: ServerConnectionDraft

    #if os(iOS)
    @State
    private var locationPermissionStatus = AppPermission.location.status
    #endif

    @Toaster
    private var toaster

    private let initialConnection: ServerConnection
    private let initialDraft: ServerConnectionDraft

    private var existingConnection: ServerConnection? {
        viewModel.connections.first { $0.id == initialConnection.id }
    }

    private var connection: ServerConnection {
        existingConnection ?? initialConnection
    }

    private var isExistingConnection: Bool {
        existingConnection != nil
    }

    private var testState: ServerConnection.TestState {
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

    #if os(iOS)
    @ViewBuilder
    private var locationPermissionWarning: some View {

        if draft.interface == .wifi,
           locationPermissionStatus != .authorized,
           AppPermission.location.privacyDescription.isNotEmpty
        {
            Label(
                AppPermission.location.privacyDescription,
                systemImage: "exclamationmark.circle.fill"
            )
            .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
        }
    }
    #endif

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
        #if os(iOS)
        Task { @MainActor in
            guard let ssid = await NetworkConnectionContext.currentWifiSSID() else {
                draft.useWifiName = keepSpecificOnFailure
                return
            }

            draft.wifiSSID = ssid
            draft.useWifiName = true
        }
        #endif
    }

    private func test(_ connection: ServerConnection) {
        Task {
            let state = await viewModel.testConnection(connection)

            switch state {
            case .idle, .testing:
                break
            case .success:
                toaster.present(L10n.connected, systemName: "checkmark.circle.fill")
            case .failure:
                toaster.present(L10n.connectionFailed, systemName: "xmark.circle.fill")
            }
        }
    }

    var body: some View {
        Form(systemImage: "network") {
            Section(L10n.name) {
                TextField(L10n.name, text: $draft.name)
                    .focused($isNameFocused)
            }

            Section(L10n.url) {
                TextField(L10n.url, text: $draft.urlString)
                #if !os(tvOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                #endif
            }

            #if os(iOS)
            Section {
                Picker(L10n.network, selection: $draft.interface) {
                    ForEach(ServerConnectionInterface.allCases, id: \.self) { interface in
                        Label(interface.displayTitle, systemImage: interface.systemImage)
                            .tag(interface)
                    }
                }

                if draft.interface == .wifi {
                    Toggle(L10n.wifiName, isOn: $draft.useWifiName)

                    if draft.useWifiName {
                        TextField(L10n.wifiName, text: $draft.wifiSSID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            } header: {
                Text(L10n.network)
            } footer: {
                locationPermissionWarning
            }
            #endif

            Section(L10n.status) {
                if isCurrentConnection {
                    Label(L10n.active, systemImage: "circle.fill")
                        .foregroundStyle(.green)
                } else if isExistingConnection {
                    Button(L10n.use) {
                        setActiveConnection(connection)
                    }
                    .disabled(isTesting || hasChanges)
                }

                Button(action: testDraft) {
                    LabeledContent {
                        switch testState {
                        case .idle, .failure:
                            EmptyView()
                        case .testing:
                            ProgressView()
                        case .success:
                            Image(systemName: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } label: {
                        Text(L10n.test)
                    }
                }
                .disabled(isTesting)

                if case let .failure(message) = testState {
                    Text(message.nilIfBlank ?? L10n.connectionFailed)
                        .foregroundStyle(.red)
                }
            }

            if isExistingConnection {
                Button(L10n.delete, role: .destructive) {
                    viewModel.deleteConnection(connection)
                    router.dismiss()
                }
                .disabled(viewModel.connections.count <= 1 || isCurrentConnection)
            }
        }
        .navigationTitle(L10n.connection)
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
        .animation(.linear(duration: 0.1), value: draft.useWifiName)
        .onFirstAppear {
            isNameFocused = true
        }
        #if os(iOS)
        .backport
        .onChange(of: draft.interface) { _, newValue in
            guard newValue == .wifi, draft.wifiSSID.nilIfBlank == nil else { return }
            populateCurrentWifiSSID(keepSpecificOnFailure: false)
        }
        .backport
        .onChange(of: draft.useWifiName) { _, newValue in
            guard newValue, draft.interface == .wifi, draft.wifiSSID.nilIfBlank == nil else { return }
            populateCurrentWifiSSID(keepSpecificOnFailure: true)
        }
        .onAppear {
            locationPermissionStatus = AppPermission.location.status
        }
        .onNotification(.applicationWillEnterForeground) {
            locationPermissionStatus = AppPermission.location.status
        }
        #endif
    }
}

private struct ServerConnectionDraft: Equatable {
    let id: String
    var name: String
    var urlString: String
    var interface: ServerConnectionInterface
    var wifiSSID: String
    var priority: Int
    var useWifiName: Bool

    init(connection: ServerConnection) {
        self.id = connection.id
        self.name = connection.name
        self.urlString = connection.url.absoluteString
        #if os(tvOS)
        self.interface = .any
        self.wifiSSID = .empty
        #else
        self.interface = connection.interface
        self.wifiSSID = connection.wifiSSID
        #endif
        self.priority = connection.priority
        #if os(tvOS)
        self.useWifiName = false
        #else
        self.useWifiName = connection.interface == .wifi && connection.wifiSSID.nilIfBlank != nil
        #endif
    }

    var formattedURL: URL? {
        let formattedURL = urlString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prepending("http://", if: !urlString.contains("://"))

        return URL(string: formattedURL)?.normalizedServerConnectionURL
    }

    var connectionInterface: ServerConnectionInterface {
        #if os(tvOS)
        .any
        #else
        interface
        #endif
    }

    var connectionWifiSSID: String {
        #if os(tvOS)
        .empty
        #else
        let normalizedSSID = wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
        return interface == .wifi && useWifiName ? normalizedSSID : .empty
        #endif
    }

    var validationError: String? {
        guard let formattedURL, formattedURL.host != nil else { return L10n.invalidURL }

        #if !os(tvOS)
        let normalizedSSID = wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
        if interface == .wifi, useWifiName, normalizedSSID.nilIfBlank == nil {
            return L10n.invalidX(L10n.wifiName)
        }
        #endif

        return nil
    }

    func connection() -> ServerConnection? {
        guard validationError == nil, let url = formattedURL else { return nil }

        return ServerConnection(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url,
            interface: connectionInterface,
            wifiSSID: connectionWifiSSID,
            priority: priority
        )
    }
}
