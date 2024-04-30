//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

struct ConnectToServerView: View {

    @EnvironmentObject
    private var router: UserListCoordinator.Router

    @FocusState
    private var isURLFocused: Bool

    @State
    private var duplicateServer: ServerState? = nil
    @State
    private var error: Error? = nil
    @State
    private var isPresentingDuplicateServer: Bool = false
    @State
    private var isPresentingError: Bool = false
    @State
    private var url: String = ""

    @StateObject
    private var viewModel = ConnectToServerViewModel()

    private let timer = Timer.publish(every: 12, on: .main, in: .common).autoconnect()

    var body: some View {
        List {
            Section(L10n.connectToServer) {

                TextField(L10n.serverURL, text: $url)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .focused($isURLFocused)

                if viewModel.state == .connecting {
                    Button(L10n.cancel, role: .destructive) {
                        viewModel.send(.cancel)
                    }
                } else {
                    Button(L10n.connect) {
                        viewModel.send(.connect(url))
                    }
                    .disabled(url.isEmpty)
                }
            }

            Section {
                if viewModel.discoveredServers.isEmpty {
                    L10n.noLocalServersFound.text
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.discoveredServers) { server in
                        Button {
                            url = server.currentURL.absoluteString
                            viewModel.send(.connect(server.currentURL.absoluteString))
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(server.name)
                                    .font(.title3)

                                Text(server.currentURL.absoluteString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .disabled(viewModel.state == .connecting)
                    }
                }
            } header: {
                HStack {
                    L10n.localServers.text

                    Spacer()

                    if viewModel.backgroundStates.contains(.searching) {
                        ProgressView()
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.state == .connecting)
        .navigationTitle(L10n.connect)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .connecting) {
            router.popLast()
        }
        .onFirstAppear {
            isURLFocused = true
            viewModel.send(.searchForServers)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .connected(server):
                Notifications[.didConnectToServer].post(object: server)
                router.popLast()
            case let .duplicateServer(server):
                duplicateServer = server
                isPresentingDuplicateServer = true
            case let .error(error):
                self.error = error
                isPresentingError = true
            }
        }
        .onReceive(timer) { _ in
            guard viewModel.state != .connecting else { return }

            viewModel.send(.searchForServers)
        }
        .topBarTrailing {
            if viewModel.state == .connecting {
                ProgressView()
            }
        }
        .alert(
            L10n.server.text,
            isPresented: $isPresentingDuplicateServer,
            presenting: duplicateServer
        ) { server in
            Button(L10n.dismiss, role: .destructive)

            Button(L10n.addURL) {
                viewModel.send(.addNewURL(server))
            }
        } message: { server in
            Text("\(server.name) is already connected.")
        }
        .alert(
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .destructive)
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
