//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Engine
import SwiftUI

#if os(iOS)
import LocalAuthentication
#endif

// TODO: present toast when authentication successfully changed

struct LocalUserSecurityView: View {

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @StateObject
    private var viewModel = LocalUserSecurityViewModel()

    @State
    private var signInPolicy: UserAccessPolicy = .none
    @State
    private var pin: String = ""
    @State
    private var pinHint: String = ""
    @State
    private var isPresentingOldPinPrompt: Bool = false
    @State
    private var isPresentingNewPinPrompt: Bool = false
    @State
    private var error: Error? = nil

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

    #if os(iOS)
    private func performDeviceAuthentication(reason: String) async throws {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            viewModel.logger.critical("\(policyError!.localizedDescription)")
            error = ErrorMessage(L10n.unableToPerformDeviceAuthFaceID)
            throw ErrorMessage(L10n.deviceAuthFailed)
        }

        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            viewModel.logger.critical("\(error.localizedDescription)")
            self.error = ErrorMessage(L10n.unableToPerformDeviceAuth)
            throw ErrorMessage(L10n.deviceAuthFailed)
        }
    }
    #endif

    @MainActor
    private func handleEvent(_ event: LocalUserSecurityViewModel.Event) async throws {
        switch event {
        case let .error(eventError):
            UIDevice.feedback(.error)
            error = eventError

        case .promptForOldDeviceAuth:
            #if os(iOS)
            try await performDeviceAuthentication(
                reason: L10n.userRequiresDeviceAuthentication(viewModel.userSession.user.username)
            )
            checkNewPolicy()
            #endif

        case .promptForOldPin:
            pin = ""
            isPresentingOldPinPrompt = true

        case .promptForNewDeviceAuth:
            #if os(iOS)
            try await performDeviceAuthentication(
                reason: L10n.userRequiresDeviceAuthentication(viewModel.userSession.user.username)
            )
            viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: "")
            router.dismiss()
            #endif

        case .promptForNewPin:
            pin = ""
            isPresentingNewPinPrompt = true
        }
    }

    var body: some View {
        Form(systemImage: "lock.fill") {
            securitySection

            if signInPolicy == .requirePin {
                Section {
                    #if os(iOS)
                    TextField(L10n.hint, text: $pinHint)
                    #else
                    StateAdapter(initialValue: (isPresented: false, hint: pinHint)) { alert in
                        ChevronButton(L10n.hint, subtitle: pinHint) {
                            alert.isPresented.wrappedValue = true
                        }
                        .alert(L10n.hint, isPresented: alert.isPresented) {
                            TextField(L10n.hint, text: alert.hint)

                            Button(L10n.save) {
                                pinHint = alert.hint.wrappedValue
                            }

                            Button(L10n.cancel, role: .cancel) {}
                        } message: {
                            Text(L10n.setPinHintDescription)
                        }
                    }
                    #endif
                } header: {
                    Text(L10n.hint)
                } footer: {
                    Text(L10n.setPinHintDescription)
                }
            }
        }
        .animation(.linear, value: signInPolicy)
        .navigationTitle(L10n.security)
        .onFirstAppear {
            signInPolicy = viewModel.userSession.user.accessPolicy
            pinHint = viewModel.userSession.user.pinHint
        }
        .onReceive(viewModel.events) { event in
            Task {
                try await handleEvent(event)
            }
        }
        .topBarTrailing {
            Button(
                signInPolicy == .requirePin && signInPolicy == viewModel.userSession.user.accessPolicy
                    ? L10n.changePin
                    : L10n.save,
                action: checkOldPolicy
            )
            #if os(iOS)
            .buttonStyle(.toolbarPill)
            #endif
        }
        .alert(
            L10n.enterPin,
            isPresented: $isPresentingOldPinPrompt
        ) {
            pinField

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure
            Button(L10n.continue) {
                Task {
                    try viewModel.check(oldPin: pin)
                    checkNewPolicy()
                }
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.enterPinForUser(viewModel.userSession.user.username))
        }
        .alert(
            L10n.setPin,
            isPresented: $isPresentingNewPinPrompt
        ) {
            pinField

            // bug in SwiftUI: having .disabled will dismiss
            // alert but not call the closure
            Button(L10n.set) {
                viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: pinHint)
                router.dismiss()
            }

            Button(L10n.cancel, role: .cancel) {}
        } message: {
            Text(L10n.createPinForUser(viewModel.userSession.user.username))
        }
        .errorMessage($error)
    }

    private var pinField: some View {
        TextField(L10n.pin, text: $pin)
            .keyboardType(.numberPad)
    }

    @ViewBuilder
    private var securitySection: some View {
        Section(L10n.security) {
            #if os(iOS)
            Picker(L10n.security, selection: $signInPolicy)
            #else
            Toggle(
                L10n.pin,
                isOn: $signInPolicy.map(
                    getter: { $0 == .requirePin },
                    setter: { $0 ? .requirePin : .none }
                )
            )
            #endif
        } footer: {
            Text(L10n.additionalSecurityAccessDescription)
        } learnMore: {
            LabeledContent(
                UserAccessPolicy.none.displayTitle,
                value: L10n.saveUserWithoutAuthDescription
            )
            #if os(iOS)
            LabeledContent(
                UserAccessPolicy.requireDeviceAuthentication.displayTitle,
                value: L10n.requireDeviceAuthDescription
            )
            #endif
            LabeledContent(
                UserAccessPolicy.requirePin.displayTitle,
                value: L10n.requirePinDescription
            )
        }
    }
}
