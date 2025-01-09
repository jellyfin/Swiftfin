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
    private var router: BasicNavigationViewCoordinator.Router

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

    // MARK: - Focus Management

    @FocusState
    private var focusedItem: FocusableItem?

    private enum FocusableItem: Hashable {
        case security
    }

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

    // MARK: - Event Handler

    private func onReceive(_ event: UserLocalSecurityViewModel.Event) {
        switch event {
        case let .error(eventError):
            error = eventError
        case .promptForOldPin:
            onPinCompletion = {
                Task {
                    try viewModel.check(oldPin: pin)

                    checkNewPolicy()
                }
            }

            pin = ""
            isPresentingOldPinPrompt = true
        case .promptForNewPin:
            onPinCompletion = {
                viewModel.set(newPolicy: signInPolicy, newPin: pin, newPinHint: pinHint)
                router.popLast()
            }

            pin = ""
            isPresentingNewPinPrompt = true
        case .promptForOldDeviceAuth, .promptForNewDeviceAuth:
            break
        }
    }

    // MARK: - Body

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                descriptionView
            }
            .contentView {
                Section {
                    Toggle(
                        L10n.pin,
                        isOn: Binding<Bool>(
                            get: { signInPolicy == .requirePin },
                            set: { signInPolicy = $0 ? .requirePin : .none }
                        )
                    )
                    .focused($focusedItem, equals: .security)
                    /* Picker(L10n.security, selection: $signInPolicy) {
                         ForEach(UserAccessPolicy.allCases.filter { $0 != .requireDeviceAuthentication }, id: \.self) { policy in
                             Text(policy.displayTitle)
                         }
                     } */
                }

                if signInPolicy == .requirePin {
                    Section {
                        ChevronAlertButton(
                            L10n.hint,
                            subtitle: pinHint,
                            description: L10n.setPinHintDescription
                        ) {
                            // TODO: Verify on tvOS 18
                            // https://forums.developer.apple.com/forums/thread/739545
                            // TextField(L10n.hint, text: $pinHint)
                            TextField(text: $pinHint) {}
                        }
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
                pinHint = viewModel.userSession.user.pinHint
                signInPolicy = viewModel.userSession.user.accessPolicy
            }
            .onReceive(viewModel.events) { event in
                onReceive(event)
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

                // TODO: Verify on tvOS 18
                // https://forums.developer.apple.com/forums/thread/739545
                // SecureField(L10n.pin, text: $pin)
                SecureField(text: $pin) {}
                    .keyboardType(.numberPad)

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

                // TODO: Verify on tvOS 18
                // https://forums.developer.apple.com/forums/thread/739545
                // SecureField(L10n.pin, text: $pin)
                SecureField(text: $pin) {}
                    .keyboardType(.numberPad)

                Button(L10n.set) {
                    completion()
                }

                Button(L10n.cancel, role: .cancel) {}
            } message: { _ in
                Text(L10n.createPinForUser(viewModel.userSession.user.username))
            }
            .errorMessage($error)
    }

    // MARK: - Description View Icon

    private var descriptionView: some View {
        ZStack {
            Image(systemName: "lock.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)

            focusedDescription
                .transition(.opacity.animation(.linear(duration: 0.2)))
        }
    }

    // MARK: - Description View on Focus

    @ViewBuilder
    private var focusedDescription: some View {
        switch focusedItem {
        case .security:
            LearnMoreModal {
                TextPair(
                    title: L10n.security,
                    subtitle: L10n.additionalSecurityAccessDescription
                )
                TextPair(
                    title: UserAccessPolicy.requirePin.displayTitle,
                    subtitle: L10n.requirePinDescription
                )
                TextPair(
                    title: UserAccessPolicy.none.displayTitle,
                    subtitle: L10n.saveUserWithoutAuthDescription
                )
            }

        case nil:
            EmptyView()
        }
    }
}
