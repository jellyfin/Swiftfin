//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import Stinsen
import SwiftUI

struct UserSignInView: View {
    enum FocusedField {
        case username
        case password
    }

    @FocusState
    private var focusedField: FocusedField?

    @ObservedObject
    var viewModel: UserSignInViewModel

    @State
    private var isPresentingQuickConnect: Bool = false
    @State
    private var isPresentingSignInError: Bool = false
    @State
    private var password: String = ""
    @State
    private var username: String = ""

    @ViewBuilder
    private var signInForm: some View {
        VStack(alignment: .leading) {
            Section {
                TextField(L10n.username, text: $username)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .username)

                SecureField(L10n.password, text: $password)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .password)

                Button {
                    viewModel.send(.signInWithUserPass(username: username, password: password))
                } label: {
                    HStack {
                        if case viewModel.state = .signingIn {
                            ProgressView()
                        }

                        L10n.connect.text
                            .bold()
                            .font(.callout)
                    }
                    .frame(height: 75)
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isLoading || username.isEmpty ? .secondary : Color.jellyfinPurple)
                }
                .disabled(viewModel.isLoading || username.isEmpty)
                .buttonStyle(.card)

                Button {
                    isPresentingQuickConnect = true
                } label: {
                    L10n.quickConnect.text
                        .frame(height: 75)
                        .frame(maxWidth: .infinity)
                        .background(Color.jellyfinPurple)
                }
                .buttonStyle(.card)
            } header: {
                L10n.signInToServer(viewModel.server.name).text
            }
        }
    }

    @ViewBuilder
    private var publicUsersGrid: some View {
        VStack {
            L10n.publicUsers.text
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)

            if viewModel.publicUsers.isEmpty {
                L10n.noPublicUsers.text
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -50)
            } else {
                CollectionVGrid(
                    viewModel.publicUsers,
                    layout: .minWidth(250, insets: .init(20), itemSpacing: 20, lineSpacing: 20)
                ) { user in
                    UserProfileButton(user: user)
                        .onSelect {
                            username = user.name ?? ""
                            focusedField = .password
                        }
                }
            }
        }
    }

    var errorText: some View {
        var text: String?
        if case let .error(error) = viewModel.state {
            text = error.localizedDescription
        }
        return Text(text ?? .emptyDash)
    }

    var body: some View {
        ZStack {
            ImageView(viewModel.userSession.client.fullURL(with: Paths.getSplashscreen()))
                .ignoresSafeArea()

            Color.black
                .opacity(0.9)
                .ignoresSafeArea()

            HStack(alignment: .top) {
                signInForm
                    .frame(maxWidth: .infinity)

                publicUsersGrid
                    .frame(maxWidth: .infinity)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationTitle(L10n.signIn)
        .onChange(of: viewModel.state) { _ in
            // If we encountered the error as we switched from quick connect cover to this view,
            // it's possible that the alert doesn't show, so wait a little bit
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPresentingSignInError = true
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingSignInError
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            errorText
        }
        .blurFullScreenCover(isPresented: $isPresentingQuickConnect) {
            QuickConnectView(
                viewModel: viewModel.quickConnectViewModel,
                isPresentingQuickConnect: $isPresentingQuickConnect,
                signIn: { authSecret in
                    self.viewModel.send(.signInWithQuickConnect(authSecret: authSecret))
                }
            )
        }
        .onAppear {
            Task {
                try? await viewModel.checkQuickConnect()
                try? await viewModel.getPublicUsers()
            }
        }
        .onDisappear {
            viewModel.send(.cancelSignIn)
        }
    }
}
