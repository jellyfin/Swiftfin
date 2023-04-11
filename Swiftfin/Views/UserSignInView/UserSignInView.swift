//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct UserSignInView: View {

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @ObservedObject
    var viewModel: UserSignInViewModel

    @State
    private var isPresentingSignInError: Bool = false
    @State
    private var password: String = ""
    @State
    private var signInError: Error?
    @State
    private var signInTask: Task<Void, Never>?
    @State
    private var username: String = ""

    @ViewBuilder
    private var signInSection: some View {
        Section {
            TextField(L10n.username, text: $username)
                .disableAutocorrection(true)
                .autocapitalization(.none)

            SecureField(L10n.password, text: $password)
                .disableAutocorrection(true)
                .autocapitalization(.none)

            if viewModel.isLoading {
                Button(role: .destructive) {
                    viewModel.isLoading = false
                    signInTask?.cancel()
                } label: {
                    L10n.cancel.text
                }
            } else {
                Button {
                    let task = Task {
                        viewModel.isLoading = true

                        do {
                            try await viewModel.signIn(username: username, password: password)
                        } catch {
                            signInError = error
                            isPresentingSignInError = true
                        }

                        viewModel.isLoading = false
                    }
                    signInTask = task
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
                        .disabled(viewModel.isLoading)
                }
            }
        } header: {
            HStack {
                L10n.publicUsers.text

                Spacer()

                Button {
                    Task {
                        try? await viewModel.getPublicUsers()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .headerProminence(.increased)
    }

    var body: some View {
        List {

            signInSection

            if viewModel.quickConnectEnabled {
                Button {
                    router.route(to: \.quickConnect)
                } label: {
                    L10n.quickConnect.text
                }
            }

            publicUsersSection
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingSignInError
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(signInError?.localizedDescription ?? .emptyDash)
        }
        .navigationTitle(L10n.signIn)
        .onAppear {
            Task {
                try? await viewModel.checkQuickConnect()
                try? await viewModel.getPublicUsers()
            }
        }
        .onDisappear {
            viewModel.isLoading = false
            viewModel.stopQuickConnectAuthCheck()
        }
    }
}
