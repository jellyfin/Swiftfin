//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct ResetUserPasswordView: View {

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

            UnmaskSecureField("Current Password", text: $currentPassword) {
                focusedPassword = 1
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.none)
            .focused($focusedPassword, equals: 0)

            Section {
                UnmaskSecureField("New Password", text: $newPassword) {
                    focusedPassword = 2
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 1)

                UnmaskSecureField("Confirm New Password", text: $confirmNewPassword) {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedPassword, equals: 2)
            } footer: {
                if newPassword != confirmNewPassword {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)

                        Text("New passwords do not match")
                    }
                }
            }

            ListRowButton("Reset") {
                viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
            }
            .disabled(newPassword != confirmNewPassword || viewModel.state == .resetting)
            .foregroundStyle(.primary, Color.accentColor)
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
            Button(L10n.dismiss, role: .destructive)
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
        }
    }
}
