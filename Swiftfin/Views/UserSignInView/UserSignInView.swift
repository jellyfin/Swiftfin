//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import LocalAuthentication
import Stinsen
import SwiftUI

// TODO: ignore device authentication `canceled by user` NSError
// TODO: fix duplicate user
//       - could be good to replace access token
//       - check against current user policy

struct UserSignInView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    @FocusState
    private var focusedTextField: Int?

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @StateObject
    private var viewModel: UserSignInViewModel

    // MARK: - User Signin Variables

    @State
    private var duplicateUser: UserState? = nil
    @State
    private var onPinCompletion: (() -> Void)? = nil
    @State
    private var password: String = ""
    @State
    private var pin: String = ""
    @State
    private var pinHint: String = ""
    @State
    private var accessPolicy: UserAccessPolicy = .none
    @State
    private var username: String = ""

    // MARK: - Error State

    @State
    private var isPresentingDuplicateUser: Bool = false
    @State
    private var isPresentingLocalPin: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Initializer

    init(server: ServerState) {
        self._viewModel = StateObject(wrappedValue: UserSignInViewModel(server: server))
    }

    // MARK: - Handle Sign In

    private func handleSignIn(_ event: UserSignInViewModel.Event) {
        switch event {
        case let .duplicateUser(duplicateUser):
            UIDevice.impact(.medium)

            self.duplicateUser = duplicateUser
            isPresentingDuplicateUser = true
        case let .error(eventError):
            UIDevice.feedback(.error)
            error = eventError
        case let .signedIn(user):
            UIDevice.feedback(.success)

            Defaults[.lastSignedInUserID] = .signedIn(userID: user.id)
            Container.shared.currentUserSession.reset()
            Notifications[.didSignIn].post()
        }
    }

    // MARK: - Open Quick Connect

    // TODO: don't have multiple ways to handle device authentication vs required pin
    private func openQuickConnect(needsPin: Bool = true) {
        Task {
            switch accessPolicy {
            case .none: ()
            case .requireDeviceAuthentication:
                try await performDeviceAuthentication(reason: L10n.requireDeviceAuthForQuickConnectUser)
            case .requirePin:
                if needsPin {
                    onPinCompletion = {
                        router.route(to: \.quickConnect, viewModel.quickConnect)
                    }
                    isPresentingLocalPin = true
                    return
                }
            }

            router.route(to: \.quickConnect, viewModel.quickConnect)
        }
    }

    // MARK: - Sign In User Password

    private func signInUserPassword(needsPin: Bool = true) {
        Task {
            switch accessPolicy {
            case .none: ()
            case .requireDeviceAuthentication:
                try await performDeviceAuthentication(reason: L10n.requireDeviceAuthForUser(username))
            case .requirePin:
                if needsPin {
                    onPinCompletion = {
                        viewModel.send(.signIn(username: username, password: password, policy: accessPolicy))
                    }
                    isPresentingLocalPin = true
                    return
                }
            }

            viewModel.send(.signIn(username: username, password: password, policy: accessPolicy))
        }
    }

    // MARK: - Sign In Duplicate User

    private func signInDuplicate(user: UserState, needsPin: Bool = true, replace: Bool) {
        Task {
            switch user.accessPolicy {
            case .none: ()
            case .requireDeviceAuthentication:
                try await performDeviceAuthentication(reason: L10n.userRequiresDeviceAuthentication(user.username))
            case .requirePin:
                onPinCompletion = {
                    viewModel.send(.signInDuplicate(user, replace: replace))
                }
                isPresentingLocalPin = true
                return
            }

            viewModel.send(.signInDuplicate(user, replace: replace))
        }
    }

    // MARK: - Perform Pin Authentication

    private func performPinAuthentication() async throws {
        isPresentingLocalPin = true

        guard pin.count > 4, pin.count < 30 else {
            throw JellyfinAPIError(L10n.deviceAuthFailed)
        }
    }

    // MARK: - Perform Device Authentication

    // error logging/presentation is handled within here, just
    // use try+thrown error in local Task for early return
    private func performDeviceAuthentication(reason: String) async throws {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            viewModel.logger.critical("\(policyError!.localizedDescription)")

            await MainActor.run {
                self
                    .error =
                    JellyfinAPIError(L10n.unableToPerformDeviceAuthFaceID)
            }

            throw JellyfinAPIError(L10n.deviceAuthFailed)
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            viewModel.logger.critical("\(error.localizedDescription)")

            await MainActor.run {
                self.error = JellyfinAPIError(L10n.unableToPerformDeviceAuth)
            }

            throw JellyfinAPIError(L10n.deviceAuthFailed)
        }
    }

    // MARK: - Sign In Section

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

            UnmaskSecureField(L10n.password, text: $password) {
                focusedTextField = nil

                signInUserPassword()
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .focused($focusedTextField, equals: 1)
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
            ListRowButton(L10n.cancel) {
                viewModel.send(.cancel)
            }
            .foregroundStyle(.red, .red.opacity(0.2))
        } else {
            ListRowButton(L10n.signIn) {
                focusedTextField = nil

                signInUserPassword()
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
                    openQuickConnect()
                }
                .disabled(viewModel.state == .signingIn)
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
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

    // MARK: - Body

    var body: some View {
        List {
            signInSection

            publicUsersSection
        }
        .animation(.linear, value: viewModel.isQuickConnectEnabled)
        .interactiveDismissDisabled(viewModel.state == .signingIn)
        .navigationTitle(L10n.signIn)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state == .signingIn) {
            router.dismissCoordinator()
        }
        .onChange(of: isPresentingLocalPin) { newValue in
            if newValue {
                pin = ""
            } else {
                onPinCompletion = nil
            }
        }
        .onChange(of: pin) { newValue in
            StoredValues[.Temp.userLocalPin] = newValue
        }
        .onChange(of: pinHint) { newValue in
            StoredValues[.Temp.userLocalPinHint] = newValue
        }
        .onChange(of: accessPolicy) { newValue in
            // necessary for Quick Connect sign in, but could
            // just use for general sign in
            StoredValues[.Temp.userAccessPolicy] = newValue
        }
        .onReceive(viewModel.events) { event in
            handleSignIn(event)
        }
        .onFirstAppear {
            focusedTextField = 0
            viewModel.send(.getPublicData)
        }
        .topBarTrailing {
            if viewModel.state == .signingIn || viewModel.backgroundStates.contains(.gettingPublicData) {
                ProgressView()
            }

            Button(L10n.security, systemImage: "gearshape.fill") {
                let parameters = UserSignInCoordinator.SecurityParameters(
                    pinHint: $pinHint,
                    accessPolicy: $accessPolicy
                )
                router.route(to: \.security, parameters)
            }
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
        .alert(
            L10n.setPin,
            isPresented: $isPresentingLocalPin,
            presenting: onPinCompletion
        ) { completion in

            TextField(L10n.pin, text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button(L10n.signIn) {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text(L10n.setPinForNewUser)
        }
        .errorMessage($error)
    }
}
