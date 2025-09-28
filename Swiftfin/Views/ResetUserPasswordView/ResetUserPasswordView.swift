//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ResetUserPasswordView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    private enum Field: Hashable {
        case currentPassword
        case newPassword
        case confirmNewPassword
    }

    @FocusState
    private var focusedField: Field?

    // MARK: - State & Environment Objects

    @Router
    private var router

    @StateObject
    private var viewModel: ResetUserPasswordViewModel

    // MARK: - Password Variables

    @State
    private var currentPassword: String = ""
    @State
    private var newPassword: String = ""
    @State
    private var confirmNewPassword: String = ""

    private let requiresCurrentPassword: Bool

    // MARK: - Dialog States

    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Initializer

    init(userID: String, requiresCurrentPassword: Bool) {
        self._viewModel = StateObject(wrappedValue: ResetUserPasswordViewModel(userID: userID))
        self.requiresCurrentPassword = requiresCurrentPassword
    }

    // MARK: - Body

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
            }

            Section {
                if viewModel.state == .resetting {
                    ListRowButton(L10n.cancel) {
                        viewModel.send(.cancel)

                        if requiresCurrentPassword {
                            focusedField = .currentPassword
                        } else {
                            focusedField = .newPassword
                        }
                    }
                    .foregroundStyle(.red, .red.opacity(0.2))
                } else {
                    ListRowButton(L10n.save) {
                        focusedField = nil
                        viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                    }
                    .disabled(newPassword != confirmNewPassword || viewModel.state == .resetting)
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .opacity(newPassword != confirmNewPassword ? 0.5 : 1)
                }
            } footer: {
                Text(L10n.passwordChangeWarning)
            }
        }
        .interactiveDismissDisabled(viewModel.state == .resetting)
        .navigationBarBackButtonHidden(viewModel.state == .resetting)
        .navigationTitle(L10n.password)
        .navigationBarTitleDisplayMode(.inline)
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
