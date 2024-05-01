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
    private var isUsernameFocused: Bool

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
                .focused($isUsernameFocused)

            UnmaskSecureField(L10n.password, text: $password)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)

            if case .signingIn = viewModel.state {
                Button(L10n.cancel, role: .destructive) {
                    viewModel.send(.cancel)
                }
            } else {
                Button(L10n.signIn) {
                    viewModel.send(.signIn(username: username, password: password))
                }
                .disabled(username.isEmpty)
            }
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
                    PublicUserSignInView(viewModel: viewModel, publicUser: user)
                }
            }
        }
        .headerProminence(.increased)
    }

    var body: some View {
        List {
            signInSection

            if viewModel.isQuickConnectEnabled {
                Button {
                    router.route(to: \.quickConnect, viewModel.quickConnect)
                } label: {
                    L10n.quickConnect.text
                }
            }

            publicUsersSection
        }
        .interactiveDismissDisabled(viewModel.state == .signingIn)
        .animation(.linear, value: viewModel.isQuickConnectEnabled)
        .navigationTitle(L10n.signIn)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .signingIn) {
            router.dismissCoordinator()
        }
        .onFirstAppear {
            isUsernameFocused = true
            viewModel.send(.getPublicData)
        }
    }
}
