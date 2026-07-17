//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
#if os(iOS)
import UIKit
#endif

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

    private var isNameEmpty: Bool {
        draft.name.nilIfBlank == nil
    }

    private var isDuplicateConnection: Bool {
        guard let connection = try? draft.connection() else { return false }
        return ServerConnection.isDuplicate(connection, in: viewModel.connections)
    }

    private var isSaveDisabled: Bool {
        isTesting || !hasChanges || isNameEmpty || isDuplicateConnection
    }

    private var firstWifiSSID: Binding<String> {
        $draft.map(
            getter: { $0.wifiSSIDs.first ?? .empty },
            setter: { wifiSSID in
                var updatedDraft = draft

                if updatedDraft.wifiSSIDs.isEmpty {
                    updatedDraft.wifiSSIDs = [wifiSSID]
                } else {
                    updatedDraft.wifiSSIDs[0] = wifiSSID
                }

                return updatedDraft
            }
        )
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
            VStack(alignment: .leading, spacing: 8) {
                Label(
                    AppPermission.location.privacyDescription,
                    systemImage: "exclamationmark.circle.fill"
                )
                .labelStyle(.sectionFooterWithImage(imageStyle: .orange))

                if locationPermissionStatus == .denied {
                    Button(L10n.permissions) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                }
            }
        }
    }
    #endif

    private func save() async throws {
        guard !isNameEmpty else {
            throw ErrorMessage(L10n.invalidX(L10n.name))
        }

        let connection = try draft.connection()

        guard !isDuplicateConnection else {
            throw ErrorMessage(L10n.connectionAlreadyExists)
        }

        let state = await viewModel.saveConnection(connection)
        guard case .success = state else { return }

        router.dismiss()
    }

    private func testDraft() {
        guard let draftConnection = try? draft.connection() else { return }

        test(draftConnection)
    }

    private func populateCurrentWifiSSID(keepSpecificOnFailure: Bool) {
        #if os(iOS)
        Task { @MainActor in
            guard let ssid = await NetworkConnectionContext.currentWifiSSID() else {
                draft.useWifiName = keepSpecificOnFailure
                return
            }

            draft.wifiSSIDs = [ssid]
            draft.useWifiName = true
        }
        #endif
    }

    private func test(_ connection: ServerConnection) {
        Task {
            _ = await viewModel.testConnection(connection)
        }
    }

    var body: some View {
        Form(systemImage: "network") {
            Section {
                TextField(L10n.name, text: $draft.name)
                    .focused($isNameFocused)
            } header: {
                Text(L10n.name)
            } footer: {
                if isNameEmpty {
                    Label(L10n.required, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section {
                TextField(L10n.url, text: $draft.urlString)
                #if !os(tvOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                #endif
            } header: {
                Text(L10n.url)
            } footer: {
                if isDuplicateConnection {
                    Label(L10n.connectionAlreadyExists, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            #if os(iOS)
            Section {
                Picker(L10n.network, selection: $draft.interface) {
                    ForEach(ServerConnection.Interface.allCases, id: \.self) { interface in
                        Text(interface.displayTitle)
                            .tag(interface)
                    }
                }

                if draft.interface == .wifi {
                    Toggle(L10n.wifiName, isOn: $draft.useWifiName)

                    if draft.useWifiName {
                        TextField(L10n.wifiName, text: firstWifiSSID)
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
                        Task {
                            await viewModel.setActiveConnectionIfValid(connection)
                        }
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
                Button(role: .destructive) {
                    viewModel.deleteConnection(connection)
                    router.dismiss()
                } label: {
                    Text(L10n.delete)
                        .frame(maxWidth: .infinity)
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                #if os(iOS)
                    .listRowSeparator(.hidden)
                #endif
                    .fontWeight(.semibold)
                    .backport
                    .buttonStyle(.glassProminent.shadow(false))
                    .controlSize(.large)
                    .disabled(viewModel.connections.count <= 1 || isCurrentConnection)
            }
        }
        .navigationTitle(L10n.connection)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            let saveAction: () -> Void = {
                Task { try? await save() }
            }

            Group {
                #if os(iOS)
                if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
                #else
                Button(L10n.save, action: saveAction)
                #endif
            }
            .disabled(isSaveDisabled)
        }
        .animation(.linear(duration: 0.1), value: draft.interface)
        .animation(.linear(duration: 0.1), value: draft.useWifiName)
        .onFirstAppear {
            isNameFocused = true
        }
        #if os(iOS)
        .backport
        .onChange(of: draft.interface) { _, newValue in
            guard newValue == .wifi, draft.wifiSSIDs.first?.nilIfBlank == nil else { return }
            populateCurrentWifiSSID(keepSpecificOnFailure: false)
        }
        .backport
        .onChange(of: draft.useWifiName) { _, newValue in
            guard newValue, draft.interface == .wifi, draft.wifiSSIDs.first?.nilIfBlank == nil else { return }
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
    var interface: ServerConnection.Interface
    var wifiSSIDs: [String]
    var priority: Int
    var useWifiName: Bool

    init(connection: ServerConnection) {
        self.id = connection.id
        self.name = connection.name
        self.urlString = connection.url.absoluteString
        self.interface = connection.interface
        self.wifiSSIDs = connection.wifiSSIDs
        self.priority = connection.priority
        self.useWifiName = connection.interface == .wifi && connection.wifiSSIDs.isNotEmpty
    }

    var url: URL? {
        let resolvedURLString = urlString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prepending("http://", if: !urlString.contains("://"))

        return URL(string: resolvedURLString)?.normalizedServerConnectionURL
    }

    func connection() throws -> ServerConnection {
        guard let url, url.host != nil else {
            throw ErrorMessage(L10n.invalidURL)
        }

        let normalizedSSIDs = Self.normalizeSSIDs(wifiSSIDs)

        if interface == .wifi,
           useWifiName,
           normalizedSSIDs.isEmpty
        {
            throw ErrorMessage(L10n.invalidX(L10n.wifiName))
        }

        return ServerConnection(
            id: id,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url,
            interface: interface,
            wifiSSIDs: interface == .wifi && useWifiName ? normalizedSSIDs : [],
            priority: priority
        )
    }

    private static func normalizeSSIDs(_ wifiSSIDs: [String]) -> [String] {
        wifiSSIDs
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank }
            .sorted()
    }
}
