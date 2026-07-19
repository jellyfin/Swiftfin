//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ResetUserPasswordView: View {

    @Default(.accentColor)
    private var accentColor

    private enum Field: Hashable {
        case currentPassword
        case newPassword
        case confirmNewPassword
    }

    @FocusState
    private var focusedField: Field?

    @Router
    private var router

    @StateObject
    private var viewModel: ResetUserPasswordViewModel

    @State
    private var currentPassword: String = ""
    @State
    private var newPassword: String = ""
    @State
    private var confirmNewPassword: String = ""

    private let requiresCurrentPassword: Bool

    @State
    private var isPresentingSuccess: Bool = false

    @State
    private var error: Error? = nil

    init(userID: String, requiresCurrentPassword: Bool) {
        self._viewModel = StateObject(wrappedValue: ResetUserPasswordViewModel(userID: userID))
        self.requiresCurrentPassword = requiresCurrentPassword
    }

    private var isValid: Bool {
        newPassword == confirmNewPassword
    }

    var body: some View {
        List {
            if requiresCurrentPassword {
                Section(L10n.currentPassword) {
                    SecureField(
                        L10n.currentPassword,
                        text: $currentPassword,
                        maskToggle: .enabled
                    )
                    .onSubmit {
                        focusedField = .newPassword
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .focused($focusedField, equals: .currentPassword)
                    .disabled(viewModel.state == .resetting)
                }
            }

            Section(L10n.newPassword) {
                SecureField(
                    L10n.newPassword,
                    text: $newPassword,
                    maskToggle: .enabled
                )
                .onSubmit {
                    focusedField = .confirmNewPassword
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedField, equals: .newPassword)
                .disabled(viewModel.state == .resetting)
            }

            Section {
                SecureField(
                    L10n.confirmNewPassword,
                    text: $confirmNewPassword,
                    maskToggle: .enabled
                )
                .onSubmit {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedField, equals: .confirmNewPassword)
                .disabled(viewModel.state == .resetting)
            } header: {
                Text(L10n.confirmNewPassword)
            } footer: {
                if newPassword != confirmNewPassword {
                    Label(L10n.passwordsDoNotMatch, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }

                Text(L10n.passwordChangeWarning)
            }
        }
        .interactiveDismissDisabled(viewModel.state == .resetting)
        .navigationBarBackButtonHidden(viewModel.state == .resetting)
        .navigationTitle(L10n.password)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .onFirstAppear {
            if requiresCurrentPassword {
                focusedField = .currentPassword
            } else {
                focusedField = .newPassword
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            case .success:
                UIDevice.feedback(.success)
                isPresentingSuccess = true
            }
        }
        .topBarTrailing {
            if viewModel.state == .resetting {
                ProgressView()

                Button(L10n.cancel, role: .cancel) {
                    viewModel.send(.cancel)

                    if requiresCurrentPassword {
                        focusedField = .currentPassword
                    } else {
                        focusedField = .newPassword
                    }
                }
                .foregroundStyle(.primary, .secondary)
                .backport
                .buttonStyle(.glass)
                .controlSize(.small)
            } else {
                let saveAction: () -> Void = {
                    focusedField = nil
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }

                if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                    Button(
                        L10n.save,
                        role: .confirm,
                        action: saveAction
                    )
                    .enabled(isValid)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                        .enabled(isValid)
                }
            }
        }
        .alert(
            L10n.success,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.dismiss()
            }
        } message: {
            Text(L10n.passwordChangedMessage)
        }
        .errorMessage($error) {
            focusedField = .newPassword
        }
    }
}
