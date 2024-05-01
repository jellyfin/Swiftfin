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
    private var isPresentingError: Bool = false
    @State
    private var password: String = ""
    @State
    private var requireEveryTimeSignIn: Bool = false
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
                .textInputAutocapitalization(.none)
                .focused($focusedTextField, equals: 0)

            UnmaskSecureField(L10n.password, text: $password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedTextField, equals: 1)
        }

        if case .signingIn = viewModel.state {
            Button(L10n.cancel, role: .destructive) {
                viewModel.send(.cancel)
            }
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.red.opacity(0.1))
        } else {
            Button(L10n.signIn) {
                viewModel.send(.signIn(username: username, password: password))
            }
            .buttonStyle(.plain)
            .disabled(username.isEmpty)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.accentColor.opacity(username.isEmpty ? 0.5 : 1))
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
                    PublicUserButton(
                        user: user,
                        client: viewModel.server.client
                    ) {
                        username = user.name ?? ""
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
                    Button(L10n.quickConnect) {
                        router.route(to: \.quickConnect, viewModel.quickConnect)
                    }
                    .buttonStyle(.plain)
                    .font(.body.weight(.semibold))
                    .listRowBackground(Color.accentColor)
                    .frame(maxWidth: .infinity)
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
        .onFirstAppear {
            focusedTextField = 0
            viewModel.send(.getPublicData)
        }
        .topBarTrailing {
            if viewModel.state == .signingIn {
                ProgressView()
            }
        }
    }
}
