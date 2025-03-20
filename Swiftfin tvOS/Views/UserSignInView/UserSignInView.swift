//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import Stinsen
import SwiftUI

struct UserSignInView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    private enum FocusField: Hashable {
        case username
        case password
    }

    @FocusState
    private var focusedField: FocusField?

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @StateObject
    private var focusGuide: FocusGuide = .init()

    @StateObject
    private var viewModel: UserSignInViewModel

    // MARK: - User Sign In Variables

    @State
    private var duplicateUser: UserState? = nil
    @State
    private var password: String = ""
    @State
    private var username: String = ""

    // MARK: - Dialog State

    @State
    private var isPresentingDuplicateUser: Bool = false

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: UserSignInViewModel(server: server))
    }

    // MARK: - Sign In Section

    @ViewBuilder
    private var signInSection: some View {
        TextField(L10n.username, text: $username)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusedField, equals: .username)

        SecureField(L10n.password, text: $password)
            .focused($focusedField, equals: .password)
            .onSubmit {
                guard username.isNotEmpty else {
                    return
                }
                viewModel.send(.signIn(username: username, password: password, policy: .none))
            }

        if case .signingIn = viewModel.state {
            ListRowButton(L10n.cancel, role: .cancel) {
                viewModel.send(.cancel)
            }
            .padding(.vertical)
        } else {
            ListRowButton(L10n.signIn) {
                viewModel.send(.signIn(username: username, password: password, policy: .none))
            }
            .disabled(username.isEmpty)
            .foregroundStyle(
                accentColor.overlayColor,
                username.isEmpty ? Color.white.opacity(0.5) : accentColor
            )
            .opacity(username.isEmpty ? 0.5 : 1)
            .padding(.vertical)
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
                .padding(.bottom)
            }
        }

        if let disclaimer = viewModel.serverDisclaimer {
            Section(L10n.disclaimer) {
                Text(disclaimer)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            .padding(.top)
        }
    }

    // MARK: - Public Users Section

    @ViewBuilder
    private var publicUsersSection: some View {
        if viewModel.publicUsers.isEmpty {
            L10n.noPublicUsers.text
                .font(.callout)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .center)
        } else {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 4),
                spacing: 30
            ) {
                ForEach(viewModel.publicUsers, id: \.id) { user in
                    PublicUserButton(
                        user: user,
                        client: viewModel.server.client
                    ) {
                        username = user.name ?? ""
                        password = ""
                        focusedField = .password
                    }
                    .environment(
                        \.isEnabled,
                        viewModel.state != .signingIn
                    )
                }
            }
        }
    }

    // MARK: - Body

    var body: some View {
        SplitLoginWindowView(
            isLoading: viewModel.state == .signingIn,
            leadingTitle: L10n.signInToServer(viewModel.server.name),
            trailingTitle: L10n.publicUsers,
            backgroundImageSource: viewModel.server.splashScreenImageSource()
        ) {
            signInSection
        } trailingContentView: {
            publicUsersSection
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .duplicateUser(duplicateUser):
                self.duplicateUser = duplicateUser
                isPresentingDuplicateUser = true
            case let .error(eventError):
                error = eventError
            case let .signedIn(user):
                router.dismissCoordinator()

                Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
                Container.shared.currentUserSession.reset()
                Notifications[.didSignIn].post()
            }
        }
        .onFirstAppear {
            focusedField = .username
            viewModel.send(.getPublicData)
        }
        .alert(
            Text(L10n.duplicateUser),
            isPresented: $isPresentingDuplicateUser,
            presenting: duplicateUser
        ) { _ in

            // TODO: uncomment when duplicate user fixed
//            Button(L10n.signIn) {
//                signInDuplicate(user: user, replace: false)
//            }

//            Button("Replace") {
//                signInDuplicate(user: user, replace: true)
//            }

            Button(L10n.dismiss, role: .cancel)
        } message: { duplicateUser in
            Text(L10n.duplicateUserSaved(duplicateUser.username))
        }
        .errorMessage($error)
    }
}
