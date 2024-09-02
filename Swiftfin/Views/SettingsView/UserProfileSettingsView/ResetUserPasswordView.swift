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
    private var router: SettingsCoordinator.Router

    @FocusState
    private var focusedPassword: Int?

    @State
    private var currentPassword: String = ""
    @State
    private var newPassword: String = ""
    @State
    private var confirmNewPassword: String = ""

    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    @StateObject
    private var viewModel = ResetUserPasswordViewModel()

    var body: some View {
        List {

            Section("Current Password") {
                UnmaskSecureField("Current Password", text: $currentPassword) {
                    focusedPassword = 1
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 0)
                .disabled(viewModel.state == .resetting)
            }

            Section("New Password") {
                UnmaskSecureField("New Password", text: $newPassword) {
                    focusedPassword = 2
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 1)
                .disabled(viewModel.state == .resetting)
            }

            Section {
                UnmaskSecureField("Confirm New Password", text: $confirmNewPassword) {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 2)
                .disabled(viewModel.state == .resetting)
            } header: {
                Text("Confirm New Password")
            } footer: {
                if newPassword != confirmNewPassword {
                    Label("New passwords to not match", systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section {
                if viewModel.state == .resetting {
                    ListRowButton(L10n.cancel) {
                        viewModel.send(.cancel)
                        focusedPassword = 0
                    }
                    .foregroundStyle(.red, .red.opacity(0.2))
                } else {
                    ListRowButton("Save") {
                        focusedPassword = nil
                        viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                    }
                    .disabled(newPassword != confirmNewPassword || viewModel.state == .resetting)
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .opacity(newPassword != confirmNewPassword ? 0.5 : 1)
                }
            } footer: {
                Text("Changes the Jellyfin server user password. This does not change any Swiftfin settings.")
            }
        }
        .interactiveDismissDisabled(viewModel.state == .resetting)
        .navigationBarBackButtonHidden(viewModel.state == .resetting)
        .navigationTitle(L10n.password)
        .onFirstAppear {
            focusedPassword = 0
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
            L10n.error.text,
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
            "Success",
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.pop()
            }
        } message: {
            Text("User password has been changed.")
        }
    }
}
