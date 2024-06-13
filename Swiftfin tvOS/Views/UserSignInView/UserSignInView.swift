//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import Stinsen
import SwiftUI

// TODO: change public users from list to grid

struct UserSignInView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @FocusState
    private var focusedTextField: Int?

    @State
    private var duplicateUser: UserState? = nil
    @State
    private var error: Error? = nil
    @State
    private var isPresentingDuplicateUser: Bool = false
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
        Section {
            TextField(L10n.username, text: $username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedTextField, equals: 0)
                .onSubmit {
                    focusedTextField = 1
                }

            TextField(L10n.password, text: $password) {
                focusedTextField = nil
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusedTextField, equals: 1)
        } header: {
            Text(L10n.signInToServer(viewModel.server.name))
        }

        if case .signingIn = viewModel.state {
            Button(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, .red.opacity(0.2))
        } else {
            Button(L10n.signIn) {
                focusedTextField = nil

                viewModel.send(.signIn(username: username, password: password, policy: .none))
            }
            .disabled(username.isEmpty)
            .foregroundStyle(
                accentColor.overlayColor,
                accentColor
            )
            .opacity(username.isEmpty ? 0.5 : 1)
        }

        if viewModel.isQuickConnectEnabled {
            Section {
                ListRowButton(L10n.quickConnect) {
                    router.route(to: \.quickConnect, viewModel.quickConnect)
                }
                .disabled(viewModel.state == .signingIn)
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
            }
        }

        if let disclaimer = viewModel.serverDisclaimer {
            Section("Disclaimer") {
                Text(disclaimer)
                    .font(.callout)
            }
        }
    }

    @ViewBuilder
    private var publisUsersSection: some View {
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
        VStack {
            HStack {
                Spacer()

                if viewModel.state == .signingIn {
                    ProgressView()
                }
            }
            .frame(height: 100)
            .overlay {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .edgePadding()
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    signInSection
                }

                VStack(alignment: .leading) {
                    publisUsersSection
                }
            }

            Spacer()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .duplicateUser(duplicateUser):
                self.duplicateUser = duplicateUser
                isPresentingDuplicateUser = true
            case let .error(eventError):
                error = eventError
                isPresentingError = true
            case let .signedIn(user):
                router.dismissCoordinator()

                Defaults[.lastSignedInUserID] = user.id
                Container.shared.currentUserSession.reset()
                Notifications[.didSignIn].post()
            }
        }
        .onFirstAppear {
            focusedTextField = 0
            viewModel.send(.getPublicData)
        }
        .alert(
            Text("Duplicate User"),
            isPresented: $isPresentingDuplicateUser,
            presenting: duplicateUser
        ) { _ in

            // TODO: uncomment when duplicate user fixed
//            Button(L10n.signIn) {
//                signInUplicate(user: user, replace: false)
//            }

//            Button("Replace") {
//                signInUplicate(user: user, replace: true)
//            }

            Button(L10n.dismiss, role: .cancel)
        } message: { duplicateUser in
            Text("\(duplicateUser.username) is already saved")
        }
        .alert(
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .cancel)
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
