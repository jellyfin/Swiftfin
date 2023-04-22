//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
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
    private var password: String = ""
    @State
    private var signInError: Error?
    @State
    private var signInTask: Task<Void, Never>?
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
                    let task = Task {
                        viewModel.isLoading = true

                        do {
                            try await viewModel.signIn(username: username, password: password)
                        } catch {
                            signInError = error
                        }

                        viewModel.isLoading = false
                    }

                    signInTask = task
                } label: {
                    HStack {
                        if viewModel.isLoading {
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
                CollectionView(items: viewModel.publicUsers) { _, user, _ in
                    UserProfileButton(user: user)
                        .onSelect {
                            username = user.name ?? ""
                            focusedField = .password
                        }
                }
                .layout { _, layoutEnvironment in
                    .grid(
                        layoutEnvironment: layoutEnvironment,
                        layoutMode: .adaptive(withMinItemSize: 250),
                        itemSpacing: 20,
                        lineSpacing: 20,
                        sectionInsets: .init(top: 20, leading: 20, bottom: 20, trailing: 20)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var quickConnect: some View {
        VStack(alignment: .center) {
            L10n.quickConnect.text
                .font(.title3)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 20) {
                L10n.quickConnectStep1.text

                L10n.quickConnectStep2.text

                L10n.quickConnectStep3.text
            }
            .padding(.vertical)

            Text(viewModel.quickConnectCode ?? "------")
                .tracking(10)
                .font(.title)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Button {
                isPresentingQuickConnect = false
            } label: {
                L10n.close.text
                    .frame(width: 400, height: 75)
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            Task {
                for await result in viewModel.startQuickConnect() {
                    guard let secret = result.secret else { continue }
                    try? await viewModel.signIn(quickConnectSecret: secret)
                }
            }
        }
        .onDisappear {
            viewModel.stopQuickConnectAuthCheck()
        }
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
//        .alert(item: $viewModel.errorMessage) { _ in
//            Alert(
//                title: Text(viewModel.alertTitle),
//                message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
//                dismissButton: .cancel()
//            )
//        }
        .blurFullScreenCover(isPresented: $isPresentingQuickConnect) {
            quickConnect
        }
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
