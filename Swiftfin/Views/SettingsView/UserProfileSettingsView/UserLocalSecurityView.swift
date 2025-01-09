//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import KeychainSwift
import LocalAuthentication
import SwiftUI

// TODO: present toast when authentication successfully changed
// TODO: pop is just a workaround to get change published from usersession.
//       find fix and don't pop when successfully changed
// TODO: could cleanup/refactor greatly

struct UserLocalSecurityView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = UserLocalSecurityViewModel()

    // MARK: - Local Security Variables

    @State
    private var listSize: CGSize = .zero
    @State
    private var onPinCompletion: (() -> Void)?
    @State
    private var pin: String = ""
    @State
    private var pinHint: String = ""
    @State
    private var signInPolicy: UserAccessPolicy = .none

    // MARK: - Dialog States

    @State
    private var isPresentingOldPinPrompt: Bool = false
    @State
    private var isPresentingNewPinPrompt: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Check Old Policy

    private func checkOldPolicy() {
        do {
            try viewModel.checkForOldPolicy()
        } catch {
            return
        }

        checkNewPolicy()
    }

    // MARK: - Check New Policy

    private func checkNewPolicy() {
        do {
            try viewModel.checkFor(newPolicy: signInPolicy)
        } catch {
            return
        }

        viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: pinHint)
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
                    .error = JellyfinAPIError(L10n.unableToPerformDeviceAuthFaceID)
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

    // MARK: - Body

    var body: some View {
        List {

            Section {
                CaseIterablePicker(L10n.security, selection: $signInPolicy)
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.additionalSecurityAccessDescription)

                    // frame necessary with bug within BulletedList
                    BulletedList {

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.requireDeviceAuthentication.displayTitle)
                                .fontWeight(.semibold)

                            Text(L10n.requireDeviceAuthDescription)
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.requirePin.displayTitle)
                                .fontWeight(.semibold)

                            Text(L10n.requirePinDescription)
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.none.displayTitle)
                                .fontWeight(.semibold)

                            Text(L10n.saveUserWithoutAuthDescription)
                        }
                    }
                    .frame(width: max(10, listSize.width - 50))
                }
            }

            if signInPolicy == .requirePin {
                Section {
                    TextField(L10n.hint, text: $pinHint)
                } header: {
                    Text(L10n.hint)
                } footer: {
                    Text(L10n.setPinHintDescription)
                }
            }
        }
        .animation(.linear, value: signInPolicy)
        .navigationTitle(L10n.security)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            pinHint = viewModel.userSession.user.pinHint
            signInPolicy = viewModel.userSession.user.accessPolicy
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            case .promptForOldDeviceAuth:
                Task { @MainActor in
                    try await performDeviceAuthentication(
                        reason: L10n.userRequiresDeviceAuthentication(viewModel.userSession.user.username)
                    )

                    checkNewPolicy()
                }
            case .promptForOldPin:
                onPinCompletion = {
                    Task {
                        try viewModel.check(oldPin: pin)

                        checkNewPolicy()
                    }
                }

                pin = ""
                isPresentingOldPinPrompt = true
            case .promptForNewDeviceAuth:
                Task { @MainActor in
                    try await performDeviceAuthentication(
                        reason: L10n.userRequiresDeviceAuthentication(viewModel.userSession.user.username)
                    )

                    viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: "")
                    router.popLast()
                }
            case .promptForNewPin:
                onPinCompletion = {
                    viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: pinHint)
                    router.popLast()
                }

                pin = ""
                isPresentingNewPinPrompt = true
            }
        }
        .topBarTrailing {
            Button {
                checkOldPolicy()
            } label: {
                Group {
                    if signInPolicy == .requirePin, signInPolicy == viewModel.userSession.user.accessPolicy {
                        Text(L10n.changePin)
                    } else {
                        Text(L10n.save)
                    }
                }
                .foregroundStyle(accentColor.overlayColor)
                .font(.headline)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background {
                    accentColor
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .trackingSize($listSize)
        .alert(
            L10n.enterPin,
            isPresented: $isPresentingOldPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField(L10n.pin, text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button(L10n.continue) {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text(L10n.enterPinForUser(viewModel.userSession.user.username))
        }
        .alert(
            L10n.setPin,
            isPresented: $isPresentingNewPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField(L10n.pin, text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button(L10n.set) {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text(L10n.createPinForUser(viewModel.userSession.user.username))
        }
        .errorMessage($error)
    }
}
