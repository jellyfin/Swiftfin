//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import SwiftUI

struct ConnectToServerView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SelectUserCoordinator.Router

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

    private func handleConnection(_ event: ConnectToServerViewModel.Event) {
        switch event {
        case let .connected(server):
            UIDevice.feedback(.success)

            Notifications[.didConnectToServer].post(object: server)
            router.popLast()
        case let .duplicateServer(server):
            UIDevice.feedback(.warning)

            duplicateServer = server
            isPresentingDuplicateServer = true
        case let .error(eventError):
            UIDevice.feedback(.error)

            error = eventError
            isPresentingError = true
            isURLFocused = true
        }
    }

    @ViewBuilder
    private var connectSection: some View {
        Section(L10n.connectToServer) {
            TextField(L10n.serverURL, text: $url)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($isURLFocused)
        }

        if viewModel.state == .connecting {
            ListRowButton(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, .red.opacity(0.2))
        } else {
            ListRowButton(L10n.connect) {
                isURLFocused = false
                viewModel.send(.connect(url))
            }
            .disabled(url.isEmpty)
            .foregroundStyle(
                accentColor.overlayColor,
                accentColor
            )
            .opacity(url.isEmpty ? 0.5 : 1)
        }
    }

    private func localServerButton(for server: ServerState) -> some View {
        Button {
            url = server.currentURL.absoluteString
            viewModel.send(.connect(server.currentURL.absoluteString))
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(server.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(server.currentURL.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body.weight(.regular))
                    .foregroundColor(.secondary)
            }
        }
        .disabled(viewModel.state == .connecting)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var localServersSection: some View {
        Section(L10n.localServers) {
            if viewModel.localServers.isEmpty {
                L10n.noLocalServersFound.text
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.localServers) { server in
                    localServerButton(for: server)
                }
            }
        }
    }

    var body: some View {
        List {
            connectSection

            localServersSection
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
            handleConnection(event)
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
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .destructive)
        } message: { error in
            Text(error.localizedDescription)
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
            L10n.serverAlreadyExistsPrompt(server.name).text
        }
    }
}
