//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Factory
import JellyfinAPI
import Logging
import SwiftUI

struct UserSignInView: View {

    private enum Field: Hashable {
        case username
        case password
    }

    @Environment(\.localUserAuthenticationAction)
    private var authenticationAction
    @Environment(\.quickConnectAction)
    private var quickConnectAction

    @FocusState
    private var focusedTextField: Field?

    @Router
    private var router

    @State
    private var accessPolicy: UserAccessPolicy = .none
    @State
    private var existingUser: UserSignInViewModel.UserStateDataPair? = nil
    @State
    private var isPresentingExistingUser: Bool = false
    @State
    private var password: String = ""
    @State
    private var pinHint: String = ""
    @State
    private var username: String = ""

    @StateObject
    private var viewModel: UserSignInViewModel

    private let logger = Logger.swiftfin()

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: UserSignInViewModel(server: server))
    }

    private func handleEvent(_ event: UserSignInViewModel._Event) {
        switch event {
        case let .connected(user):
            guard let authenticationAction else {
                return
            }
            viewModel.save(
                user: user,
                authenticationAction: (
                    authenticationAction,
                    accessPolicy,
                    accessPolicy.createReason(
                        user: user.state.state
                    )
                ),
                evaluatedPolicyMap: .init(action: processEvaluatedPolicy)
            )
        case let .existingUser(existingUser):
            self.existingUser = existingUser
            self.isPresentingExistingUser = true
        case let .saved(user):
            UIDevice.feedback(.success)

            router.dismiss()
            Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
            Container.shared.currentUserSession.reset()
            Notifications[.didSignIn].post()
        }
    }

    private func runQuickConnect() {
        Task {
            do {
                guard let secret = try await quickConnectAction?(client: viewModel.server.client) else {
                    logger.critical("QuickConnect called without necessary action!")
                    throw ErrorMessage(L10n.unknownError)
                }
                await viewModel.signInQuickConnect(
                    secret: secret
                )
            } catch is CancellationError {
                // ignore
            } catch {
                logger.error("QuickConnect failed with error: \(error.localizedDescription)")
                await viewModel.error(ErrorMessage(L10n.taskFailed))
            }
        }
    }

    private func processEvaluatedPolicy(
        _ evaluatedPolicy: any EvaluatedLocalUserAccessPolicy
    ) -> any EvaluatedLocalUserAccessPolicy {
        if let pinPolicy = evaluatedPolicy as? PinEvaluatedUserAccessPolicy {
            return PinEvaluatedUserAccessPolicy(
                pin: pinPolicy.pin,
                pinHint: pinHint
            )
        }

        return evaluatedPolicy
    }

    // MARK: - Sign In Section

    @ViewBuilder
    private var signInSection: some View {
        Section {
            TextField(L10n.username, text: $username)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focusedTextField, equals: .username)
                .onSubmit {
                    focusedTextField = .password
                }

            SecureField(
                L10n.password,
                text: $password,
                maskToggle: .enabled
            )
            .onSubmit {
                focusedTextField = nil

                viewModel.signIn(
                    username: username,
                    password: password
                )
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusedTextField, equals: .password)
        } header: {
            Text(L10n.signInToServer(viewModel.server.name))
        } footer: {
            switch accessPolicy {
            case .requireDeviceAuthentication:
                Label(L10n.userDeviceAuthRequiredDescription, systemImage: "exclamationmark.circle.fill")
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
            case .requirePin:
                Label(L10n.userPinRequiredDescription, systemImage: "exclamationmark.circle.fill")
                    .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
            case .none:
                EmptyView()
            }
        }

        if case .signingIn = viewModel.state {
            Button(L10n.cancel, role: .cancel) {
                viewModel.cancel()
            }
            .buttonStyle(.primary)
            .frame(maxHeight: 75)
        } else {
            Button(L10n.signIn) {
                viewModel.signIn(
                    username: username,
                    password: password
                )
            }
            .buttonStyle(.primary)
            .frame(maxHeight: 75)
            .disabled(username.isEmpty)
            .foregroundStyle(
                Color.jellyfinPurple.overlayColor,
                Color.jellyfinPurple
            )
            .opacity(username.isEmpty ? 0.5 : 1)
        }

        if viewModel.isQuickConnectEnabled {
            Section {
                Button(
                    L10n.quickConnect,
                    action: runQuickConnect
                )
                .buttonStyle(.primary)
                .frame(maxHeight: 75)
                .disabled(viewModel.state == .signingIn)
                .foregroundStyle(
                    Color.jellyfinPurple.overlayColor,
                    Color.jellyfinPurple
                )
            }
        }

        if let disclaimer = viewModel.serverDisclaimer {
            Section(L10n.disclaimer) {
                Text(disclaimer)
                    .font(.callout)
            }
        }
    }

    // MARK: - Public Users Section

    @ViewBuilder
    private var publicUsersSection: some View {
        Section(L10n.publicUsers) {
            if viewModel.publicUsers.isEmpty {
                Text(L10n.noPublicUsers)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                #if os(iOS)
                ForEach(viewModel.publicUsers) { user in
                    PublicUserRow(
                        user: user,
                        client: viewModel.server.client
                    ) {
                        username = user.name ?? ""
                        password = ""
                        focusedTextField = .password
                    }
                }
                #else
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 4),
                    spacing: 30
                ) {
                    ForEach(viewModel.publicUsers) { user in
                        PublicUserButton(
                            user: user,
                            client: viewModel.server.client
                        ) {
                            username = user.name ?? ""
                            password = ""
                            focusedTextField = .password
                        }
                        .environment(\.isOverComplexContent, true)
                    }
                }
                #endif
            }
        }
        .disabled(viewModel.state == .signingIn)
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(iOS)
        List {
            signInSection

            publicUsersSection
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .signingIn) {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.state == .signingIn || viewModel.background.is(.gettingPublicData) {
                ProgressView()
            }

            Button(L10n.security, systemImage: "gearshape.fill") {
                router.route(
                    to: .userSecurity(
                        pinHint: $pinHint,
                        accessPolicy: $accessPolicy
                    )
                )
            }
        }
        #else
        SplitLoginWindowView(
            isLoading: viewModel.state == .signingIn,
            backgroundImageSource: viewModel.server.splashScreenImageSource
        ) {
            signInSection
        } trailingContentView: {
            publicUsersSection
        }
        #endif
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.signIn.localizedCapitalized)
            .interactiveDismissDisabled(viewModel.state == .signingIn)
            .onReceive(viewModel.events, perform: handleEvent)
            .onFirstAppear {
                focusedTextField = .username
                viewModel.getPublicData()
            }
            .alert(
                L10n.duplicateUser,
                isPresented: $isPresentingExistingUser,
                presenting: existingUser
            ) { existingUser in

                let userState = existingUser.state.state
                let existingUserAccessPolicy = userState.accessPolicy

                Button(L10n.signIn) {
                    viewModel.saveExisting(
                        user: existingUser,
                        replaceForAccessToken: false,
                        authenticationAction: (
                            authenticationAction!,
                            existingUserAccessPolicy,
                            existingUserAccessPolicy.authenticateReason(
                                user: userState
                            )
                        ),
                        evaluatedPolicyMap: .init(action: processEvaluatedPolicy)
                    )
                }

                Button(L10n.replace) {
                    viewModel.saveExisting(
                        user: existingUser,
                        replaceForAccessToken: true,
                        authenticationAction: (
                            authenticationAction!,
                            existingUserAccessPolicy,
                            existingUserAccessPolicy.authenticateReason(
                                user: userState
                            )
                        ),
                        evaluatedPolicyMap: .init(action: processEvaluatedPolicy)
                    )
                }

                Button(L10n.dismiss, role: .cancel)
            } message: { existingUser in
                Text(L10n.duplicateUserSaved(existingUser.state.state.username))
            }
            .errorMessage($viewModel.error)
    }
}
