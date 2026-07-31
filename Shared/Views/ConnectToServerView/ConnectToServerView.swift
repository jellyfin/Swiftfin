//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import SwiftUI

struct ConnectToServerView: View {

    @Default(.accentColor)
    private var accentColor

    @FocusState
    private var isURLFocused: Bool

    @Router
    private var router

    @State
    private var duplicateServer: ServerState? = nil

    @State
    private var url: String = ""

    @StateObject
    private var viewModel = ConnectToServerViewModel()

    private let timer = Timer.publish(every: 12, on: .main, in: .common).autoconnect()

    private func onEvent(_ event: ConnectToServerViewModel._Event) {
        switch event {
        case let .connected(server):
            UIDevice.feedback(.success)
            Notifications[.didConnectToServer].post(server)
            router.dismiss()
        case let .duplicateServer(server):
            UIDevice.feedback(.warning)
            duplicateServer = server
        }
    }

    @ViewBuilder
    private var connectSection: some View {
        Section(L10n.connectToServer) {
            TextField(L10n.url, text: $url)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($isURLFocused)
        }

        if viewModel.state == .connecting {
            Button(role: .cancel) {
                viewModel.cancel()
            } label: {
                Text(L10n.cancel)
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
            #if os(iOS)
                .controlSize(.large)
            #endif
                .frame(maxHeight: 75)
        } else {
            Button {
                isURLFocused = false
                viewModel.connect(url: url)
            } label: {
                Text(L10n.connect)
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
                .tint(accentColor)
            #if os(iOS)
                .controlSize(.large)
            #endif
                .frame(maxHeight: 75)
                .disabled(url.isEmpty)
        }
    }

    // MARK: - Local Servers Section

    @ViewBuilder
    private var localServersSection: some View {
        Section(L10n.localServers) {
            if viewModel.localServers.isEmpty {
                Text(L10n.noLocalServersFound)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.localServers) { server in
                    LocalServerButton(server: server) {
                        url = server.currentURL.absoluteString
                        viewModel.connect(url: server.currentURL.absoluteString)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(iOS)
        List {
            connectSection

            localServersSection
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .connecting) {
            router.dismiss()
        }
        #else
        SplitLoginWindowView(
            isLoading: viewModel.state == .connecting
        ) {
            connectSection
        } trailingContentView: {
            localServersSection
        }
        #endif
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.connect)
            .interactiveDismissDisabled(viewModel.state == .connecting)
            .onFirstAppear {
                isURLFocused = true
                viewModel.searchForServers()
            }
            .onReceive(timer) { _ in
                guard viewModel.state != .connecting else { return }
                viewModel.searchForServers()
            }
            .onReceive(viewModel.events, perform: onEvent)
            .onReceive(viewModel.$error) { error in
                guard error != nil else { return }
                UIDevice.feedback(.error)
                isURLFocused = true
            }
            .topBarTrailing {
                if viewModel.state == .connecting {
                    ProgressView()
                }
            }
        #if os(tvOS)
            ._alert(
                L10n.connection,
                isPresented: $duplicateServer.isNotNil()
            ) {
                if let server = duplicateServer {
                    DuplicateServerConnectionView(server: server) {
                        viewModel.addConnection(serverState: server)
                        duplicateServer = nil
                        router.dismiss()
                    }
                }
            }
        #else
            .sheet(item: $duplicateServer) { server in
                NavigationStack {
                    DuplicateServerConnectionView(server: server) {
                        viewModel.addConnection(serverState: server)
                        duplicateServer = nil
                        router.dismiss()
                    }
                }
            }
        #endif
            .errorMessage($viewModel.error)
    }
}
