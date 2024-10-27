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

struct AddServerUserView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @FocusState
    private var focusedfield: Int?

    @State
    private var username: String = ""
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
    var viewModel: ServerUsersViewModel

    var body: some View {
        List {

            Section {
                TextField(L10n.username, text: $username) {
                    focusedfield = 0
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: 0)
                .disabled(viewModel.backgroundStates.contains(.creatingUser))
            } header: {
                Text(L10n.username)
            } footer: {
                if username.isEmpty {
                    Label(L10n.usernameRequired, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section(L10n.password) {
                UnmaskSecureField(L10n.password, text: $newPassword) {
                    focusedfield = 1
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: 1)
                .disabled(viewModel.backgroundStates.contains(.creatingUser))
            }

            Section {
                UnmaskSecureField(L10n.confirmPassword, text: $confirmNewPassword) {
                    focusedfield = 2
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: 2)
                .disabled(viewModel.backgroundStates.contains(.creatingUser))
            } header: {
                Text(L10n.confirmPassword)
            } footer: {
                if newPassword != confirmNewPassword {
                    Label(L10n.passwordsDoNotMatch, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section {
                if viewModel.backgroundStates.contains(.creatingUser) {
                    ListRowButton(L10n.cancel) {
                        viewModel.send(.cancel)
                        focusedfield = 0
                    }
                    .foregroundStyle(.red, .red.opacity(0.2))
                } else {
                    ListRowButton(L10n.save) {
                        focusedfield = nil
                        viewModel.send(.createUser(username: username, password: newPassword))
                    }
                    .disabled(newPassword != confirmNewPassword || viewModel.backgroundStates.contains(.creatingUser))
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .opacity(newPassword != confirmNewPassword ? 0.5 : 1)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.backgroundStates.contains(.creatingUser))
        .navigationBarBackButtonHidden(viewModel.backgroundStates.contains(.creatingUser))
        .navigationTitle(L10n.newUser)
        .onFirstAppear {
            focusedfield = 0
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)

                error = eventError
                isPresentingError = true
            case .created:
                UIDevice.feedback(.success)

                isPresentingSuccess = true
            default:
                break
            }
        }
        .topBarTrailing {
            if viewModel.backgroundStates.contains(.creatingUser) {
                ProgressView()
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .cancel) {
                focusedfield = 1
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            L10n.success,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.pop()
            }
        } message: {
            Text(L10n.userCreatedMessage)
        }
    }
}
