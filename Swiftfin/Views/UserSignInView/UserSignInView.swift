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
    private var router: UserListCoordinator.Router

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
        Section {
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
                Button {
//                    viewModel.send(.signInWithUserPass(username: username, password: password))
                } label: {
                    L10n.signIn.text
                }
                .disabled(username.isEmpty)
            }
        } header: {
            L10n.signInToServer(viewModel.server.name).text
        }
    }

    @ViewBuilder
    private var publicUsersSection: some View {
        Section {
            if viewModel.publicUsers.isEmpty {
                L10n.noPublicUsers.text
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.publicUsers, id: \.id) { user in
                    PublicUserSignInView(viewModel: viewModel, publicUser: user)
//                        .disabled(viewModel.isLoading)
                }
            }
        } header: {
            HStack {
                L10n.publicUsers.text

                Spacer()

                Button {
                    Task {
//                        try? await viewModel.getPublicUsers()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                }
//                .disabled(viewModel.isLoading)
            }
        }
        .headerProminence(.increased)
    }

    var body: some View {
        List {
            signInSection

            if viewModel.quickConnectEnabled {
                Button {
                    router.route(to: \.quickConnect, viewModel.server)
                } label: {
                    L10n.quickConnect.text
                }
            }

            publicUsersSection
        }
//        .onChange(of: viewModel.state) { newState in
//            if case .error = newState {
//                // If we encountered the error as we switched from quick connect navigation to this view,
//                // it's possible that the alert doesn't show, so wait a little bit
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    isPresentingSignInError = true
//                }
//            }
//        }
//        .alert(
//            L10n.error,
//            isPresented: $isPresentingSignInError
//        ) {
//            Button(L10n.dismiss, role: .cancel)
//        } message: {
//            errorText
//        }
        .navigationTitle(L10n.signIn)
        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            Task {
//                try? await viewModel.checkQuickConnect()
//                try? await viewModel.getPublicUsers()
//            }
//        }
//        .onDisappear {
//            viewModel.send(.cancelSignIn)
//        }
        .onFirstAppear {
            isUsernameFocused = true
        }
    }
}
