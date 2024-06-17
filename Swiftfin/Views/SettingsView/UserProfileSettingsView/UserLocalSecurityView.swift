//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingOldPinPrompt: Bool = false
    @State
    private var isPresentingNewPinPrompt: Bool = false
    @State
    private var listSize: CGSize = .zero
    @State
    private var onPinCompletion: (() -> Void)? = nil
    @State
    private var pin: String = ""
    @State
    private var pinHint: String = ""
    @State
    private var signInPolicy: UserAccessPolicy = .none

    @StateObject
    private var viewModel = UserLocalSecurityViewModel()

    private func checkOldPolicy() {
        do {
            try viewModel.checkForOldPolicy()
        } catch {
            return
        }

        checkNewPolicy()
    }

    private func checkNewPolicy() {
        do {
            try viewModel.checkFor(newPolicy: signInPolicy)
        } catch {
            return
        }

        viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: pinHint)
    }

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
                    JellyfinAPIError(
                        "Unable to perform device authentication. You may need to enable Face ID in the Settings app for Swiftfin."
                    )
                self.isPresentingError = true
            }

            throw JellyfinAPIError("Device auth failed")
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            viewModel.logger.critical("\(error.localizedDescription)")

            await MainActor.run {
                self.error = JellyfinAPIError("Unable to perform device authentication")
                self.isPresentingError = true
            }

            throw JellyfinAPIError("Device auth failed")
        }
    }

    var body: some View {
        List {

            Section {
                CaseIterablePicker("Security", selection: $signInPolicy)
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    Text(
                        "Additional security access for users signed in to this device. This does not change any Jellyfin server user settings."
                    )

                    // frame necessary with bug within BulletedList
                    BulletedList {

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.requireDeviceAuthentication.displayTitle)
                                .fontWeight(.semibold)

                            Text("Require device authentication when signing in to the user.")
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.requirePin.displayTitle)
                                .fontWeight(.semibold)

                            Text("Require a local pin when signing in to the user. This pin is unrecoverable.")
                        }
                        .padding(.bottom, 15)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(UserAccessPolicy.none.displayTitle)
                                .fontWeight(.semibold)

                            Text("Save the user to this device without any local authentication.")
                        }
                    }
                    .frame(width: max(10, listSize.width - 50))
                }
            }

            if signInPolicy == .requirePin {
                Section {
                    TextField("Hint", text: $pinHint)
                } header: {
                    Text("Hint")
                } footer: {
                    Text("Set a hint when prompting for the pin.")
                }
            }
        }
        .animation(.linear, value: signInPolicy)
        .navigationTitle("Security")
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
                isPresentingError = true
            case .promptForOldDeviceAuth:
                Task { @MainActor in
                    try await performDeviceAuthentication(
                        reason: "User \(viewModel.userSession.user.username) requires device authentication"
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
                        reason: "User \(viewModel.userSession.user.username) requires device authentication"
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
                        Text("Change Pin")
                    } else {
                        Text("Save")
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
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .cancel)
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            "Enter Pin",
            isPresented: $isPresentingOldPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField("Pin", text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button("Continue") {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text("Enter pin for \(viewModel.userSession.user.username)")
        }
        .alert(
            "Set Pin",
            isPresented: $isPresentingNewPinPrompt,
            presenting: onPinCompletion
        ) { completion in

            TextField("Pin", text: $pin)
                .keyboardType(.numberPad)

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure (for length)
            Button("Set") {
                completion()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: { _ in
            Text("Create a pin to sign in to \(viewModel.userSession.user.username) on this device")
        }
    }
}
