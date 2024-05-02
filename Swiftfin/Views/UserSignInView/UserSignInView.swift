//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct UserSignInView: View {

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @FocusState
    private var focusedTextField: Int?

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var password: String = ""
    @State
    private var username: String = ""

    @StateObject
    private var viewModel: UserSignInViewModel

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: UserSignInViewModel(server: server))
    }

    @ViewBuilder
    private var signInSection: some View {
        Section(L10n.signInToServer(viewModel.server.name)) {
            TextField(L10n.username, text: $username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedTextField, equals: 0)
                .onSubmit {
                    focusedTextField = 1
                }

            UnmaskSecureField(L10n.password, text: $password) {
                focusedTextField = nil

                if username.isNotEmpty {
                    viewModel.send(.signIn(username: username, password: password))
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusedTextField, equals: 1)
        }

        if case .signingIn = viewModel.state {
            ListRowButton(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, .red.opacity(0.2))
        } else {
            ListRowButton(L10n.signIn) {
                focusedTextField = nil
                viewModel.send(.signIn(username: username, password: password))
            }
            .disabled(username.isEmpty)
            .foregroundStyle(
                .primary.opacity(username.isEmpty ? 0.5 : 1),
                Color.accentColor
            )
        }
    }

    @ViewBuilder
    private var publicUsersSection: some View {
        Section(L10n.publicUsers) {
            if viewModel.publicUsers.isEmpty {
                L10n.noPublicUsers.text
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.publicUsers, id: \.id) { user in
                    PublicUserRow(
                        user: user,
                        client: viewModel.server.client
                    ) {
                        username = user.name ?? ""
                        password = ""
                        focusedTextField = 1
                    }
                }
            }
        }
    }

    var body: some View {
        List {
            signInSection

            if viewModel.isQuickConnectEnabled {
                Section {
                    ListRowButton(L10n.quickConnect) {
                        router.route(to: \.quickConnect, viewModel.quickConnect)
                    }
                    .disabled(viewModel.state == .signingIn)
                    .foregroundStyle(
                        .primary,
                        Color.accentColor
                    )
                }
            }

            publicUsersSection
        }
        .animation(.linear, value: viewModel.isQuickConnectEnabled)
        .interactiveDismissDisabled(viewModel.state == .signingIn)
        .navigationTitle(L10n.signIn)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .signingIn) {
            router.dismissCoordinator()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)

                error = eventError
                isPresentingError = true
            }
        }
        .onFirstAppear {
            focusedTextField = 0
            viewModel.send(.getPublicData)
        }
        .topBarTrailing {
            if viewModel.state == .signingIn {
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
    }
}
