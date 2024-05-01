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

// Note: can't do focus manipulation with `onSubmit` because `UmmaskSecureField`
//       is a manually wrapped `UITextField`. Could implement an `onSubmit`
//       equivalent modifier but isn't a big deal.

struct ResetUserPasswordView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @FocusState
    private var isCurrentFocused: Bool

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

            UnmaskSecureField("Current Password", text: $currentPassword)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($isCurrentFocused)

            Section {
                UnmaskSecureField("New Password", text: $newPassword)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)

                UnmaskSecureField("Confirm New Password", text: $confirmNewPassword)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)

                Button("Reset") {
                    viewModel.send(.reset(current: currentPassword, new: confirmNewPassword))
                }
                .disabled(newPassword != confirmNewPassword || viewModel.state == .resetting)
            } footer: {
                if newPassword != confirmNewPassword {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)

                        Text("New passwords do not match")
                    }
                }
            }
        }
        .navigationTitle(L10n.password)
        .onFirstAppear {
            isCurrentFocused = true
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
