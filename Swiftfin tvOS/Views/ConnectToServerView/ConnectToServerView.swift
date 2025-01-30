//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import SwiftUI

struct ConnectToServerView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    @FocusState
    private var isURLFocused: Bool

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

    @StateObject
    private var viewModel = ConnectToServerViewModel()

    // MARK: - Connect to Server Variables

    @State
    private var duplicateServer: ServerState? = nil
    @State
    private var url: String = ""

    // MARK: - Dialog States

    @State
    private var isPresentingDuplicateServer: Bool = false

    // MARK: - Error States

    @State
    private var error: Error? = nil

    // MARK: - Connection Timer

    private let timer = Timer.publish(every: 12, on: .main, in: .common).autoconnect()

    // MARK: - Connect Section

    @ViewBuilder
    private var connectSection: some View {
        TextField(L10n.serverURL, text: $url)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .focused($isURLFocused)

        if viewModel.state == .connecting {
            ListRowButton(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, accentColor)
            .padding(.vertical)
        } else {
            ListRowButton(L10n.connect) {
                isURLFocused = false
                viewModel.send(.connect(url))
            }
            .disabled(url.isEmpty)
            .foregroundStyle(
                accentColor.overlayColor,
                url.isEmpty ? Color.white.opacity(0.5) : accentColor
            )
            .opacity(url.isEmpty ? 0.5 : 1)
            .padding(.vertical)
        }
    }

    // MARK: - Local Servers Section

    @ViewBuilder
    private var localServersSection: some View {
        if viewModel.localServers.isEmpty {
            L10n.noLocalServersFound.text
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 1),
                spacing: 30
            ) {
                ForEach(viewModel.localServers, id: \.id) { server in
                    LocalServerButton(server: server) {
                        url = server.currentURL.absoluteString
                        viewModel.send(.connect(server.currentURL.absoluteString))
                    }
                    .environment(
                        \.isEnabled,
                        viewModel.state != .connecting && server.currentURL.absoluteString != url
                    )
                }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        SplitLoginWindowView(
            isLoading: viewModel.state == .connecting,
            leadingTitle: L10n.connectToServer,
            trailingTitle: L10n.localServers
        ) {
            connectSection
        } trailingContentView: {
            localServersSection
        }
        .onFirstAppear {
            isURLFocused = true
            viewModel.send(.searchForServers)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .connected(server):
                Notifications[.didConnectToServer].post(server)
                router.popLast()
            case let .duplicateServer(server):
                duplicateServer = server
                isPresentingDuplicateServer = true
            case let .error(eventError):
                error = eventError
                isURLFocused = true
            }
        }
        .onReceive(timer) { _ in
            guard viewModel.state != .connecting else { return }

            viewModel.send(.searchForServers)
        }
        .alert(
            L10n.server.text,
            isPresented: $isPresentingDuplicateServer,
            presenting: duplicateServer
        ) { server in
            Button(L10n.dismiss, role: .destructive)

            Button(L10n.addURL) {
                viewModel.send(.addNewURL(server))
                router.popLast()
            }
        } message: { server in
            Text(L10n.serverAlreadyConnected(server.name))
        }
        .errorMessage($error)
    }
}
