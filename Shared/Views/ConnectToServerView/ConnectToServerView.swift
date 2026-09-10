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
    private var connectFormContent: some View {
        TextField(L10n.url, text: $url)
        #if os(iOS)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
        #endif
            .focused($isURLFocused)

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
                .frame(maxWidth: .infinity, maxHeight: 75)
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
                .frame(maxWidth: .infinity, maxHeight: 75)
                .disabled(url.isEmpty)
        }
    }

    @ViewBuilder
    private var connectSection: some View {
        Section(L10n.connectToServer) {
            connectFormContent
        }
    }

    // MARK: - Local Servers Section

    @ViewBuilder
    private var localServersContent: some View {
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

    @ViewBuilder
    private var localServersSection: some View {
        Section(L10n.localServers) {
            localServersContent
        }
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(iOS)
        List {
            connectSection

            localServersSection
        }
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .connecting) {
            router.dismiss()
        }
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.connectToServer)
                        .font(.headline)

                    connectFormContent
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.localServers)
                        .font(.headline)

                    localServersContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)
        }
        .frame(width: 800, height: 500)
        #endif
    }

    // MARK: - Body

    var body: some View {
        Group {
            contentView
            #if os(iOS)
            .navigationTitle(L10n.connect)
            #endif
            .topBarTrailing {
                if viewModel.state == .connecting {
                    ProgressView()
                }
            }
        }
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
        .sheet(item: $duplicateServer) { server in
            DuplicateServerConnectionView(server: server) {
                viewModel.addConnection(serverState: server)
                duplicateServer = nil
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
