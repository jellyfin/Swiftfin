//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct ResetUserPasswordView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @FocusState
    private var focusedPassword: Int?

    @StateObject
    private var viewModel: ResetUserPasswordViewModel

    // MARK: - Password Variables

    @State
    private var currentPassword: String = ""
    @State
    private var newPassword: String = ""
    @State
    private var confirmNewPassword: String = ""

    // MARK: - State Variables

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Initializer

    init(userId: String? = nil) {
        self._viewModel = StateObject(wrappedValue: ResetUserPasswordViewModel(userId: userId))
    }

    // MARK: - Body

    var body: some View {
        List {
            /// UserID: Server User, who is being accessed as an administrator so no current password is required.
            /// Nil: Device User, who should have the current password and may not have administrator permissions.
            if viewModel.userId == nil {
                Section(L10n.currentPassword) {
                    UnmaskSecureField(L10n.currentPassword, text: $currentPassword) {
                        focusedPassword = 1
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .focused($focusedPassword, equals: 0)
                    .disabled(viewModel.state == .resetting)
                }
            }

            Section(L10n.newPassword) {
                UnmaskSecureField(L10n.newPassword, text: $newPassword) {
                    focusedPassword = 2
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 1)
                .disabled(viewModel.state == .resetting)
            }

            Section {
                UnmaskSecureField(L10n.confirmNewPassword, text: $confirmNewPassword) {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 2)
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
                        focusedPassword = viewModel.userId == nil ? 0 : 1
                    }
                    .foregroundStyle(.red, .red.opacity(0.2))
                } else {
                    ListRowButton(L10n.save) {
                        focusedPassword = nil
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
            router.dismissCoordinator()
        }
        .onFirstAppear {
            focusedPassword = viewModel.userId == nil ? 0 : 1
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)

                error = eventError
                isPresentingError = true
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
            L10n.error,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .cancel) {
                focusedPassword = 1
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            L10n.success,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.dismissCoordinator()
            }
        } message: {
            Text(L10n.passwordChangedMessage)
        }
    }
}
