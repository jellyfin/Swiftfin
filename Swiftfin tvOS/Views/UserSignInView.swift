//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
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

    @ObservedObject
    var viewModel: UserSignInViewModel
    @State
    private var username: String = ""
    @State
    private var password: String = ""
    @State
    private var presentQuickConnect: Bool = false

    @FocusState
    private var focusedField: FocusedField?

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
                    viewModel.signIn(username: username, password: password)
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
                .buttonStyle(.plain)

                Button {
                    presentQuickConnect = true
                } label: {
                    L10n.quickConnect.text
                        .frame(height: 75)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary)
                }
                .buttonStyle(.plain)
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
        ZStack {

            BlurView()
                .ignoresSafeArea()

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
                    presentQuickConnect = false
                } label: {
                    L10n.close.text
                        .frame(width: 400, height: 75)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            viewModel.startQuickConnect {}
        }
        .onDisappear {
            viewModel.stopQuickConnectAuthCheck()
        }
    }

    var body: some View {
        ZStack {
            ImageView(ImageAPI.getSplashscreenWithRequestBuilder().url)
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
        .alert(item: $viewModel.errorMessage) { _ in
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.errorMessage?.message ?? L10n.unknownError),
                dismissButton: .cancel()
            )
        }
        .fullScreenCover(isPresented: $presentQuickConnect, onDismiss: nil) {
            quickConnect
        }
    }
}
