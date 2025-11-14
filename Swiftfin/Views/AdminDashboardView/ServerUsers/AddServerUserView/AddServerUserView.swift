//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AddServerUserView: View {

    private enum Field {
        case username
        case password
        case confirmPassword
    }

    @FocusState
    private var focusedfield: Field?

    @Router
    private var router

    @State
    private var confirmPassword: String = ""
    @State
    private var password: String = ""
    @State
    private var username: String = ""

    @StateObject
    private var viewModel = AddServerUserViewModel()

    private var isValid: Bool {
        username.isNotEmpty && password == confirmPassword
    }

    // MARK: - Body

    var body: some View {
        List {

            Section {
                TextField(L10n.username, text: $username) {
                    focusedfield = .password
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: .username)
                .disabled(viewModel.state == .addingUser)
            } header: {
                Text(L10n.username)
            } footer: {
                if username.isEmpty {
                    Label(L10n.usernameRequired, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }

            Section(L10n.password) {
                SecureField(
                    L10n.password,
                    text: $password,
                    maskToggle: .enabled
                )
                .onSubmit {
                    focusedfield = .confirmPassword
                }
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: .password)
                .disabled(viewModel.state == .addingUser)
            }

            Section {
                SecureField(
                    L10n.confirmPassword,
                    text: $confirmPassword,
                    maskToggle: .enabled
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .focused($focusedfield, equals: .confirmPassword)
                .disabled(viewModel.state == .addingUser)
            } header: {
                Text(L10n.confirmPassword)
            } footer: {
                if password != confirmPassword {
                    Label(L10n.passwordsDoNotMatch, systemImage: "exclamationmark.circle.fill")
                        .labelStyle(.sectionFooterWithImage(imageStyle: .orange))
                }
            }
        }
        .animation(.linear(duration: 0.1), value: isValid)
        .interactiveDismissDisabled(viewModel.state == .addingUser)
        .navigationTitle(L10n.newUser.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton(disabled: viewModel.state != .initial) {
            router.dismiss()
        }
        .onFirstAppear {
            focusedfield = .username
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .created(newUser):
                UIDevice.feedback(.success)
                Notifications[.didAddServerUser].post(newUser)
                router.dismiss()
            }
        }
        .topBarTrailing {
            if viewModel.state == .addingUser {
                ProgressView()
                Button(L10n.cancel) {
                    viewModel.cancel()
                }
                .buttonStyle(.toolbarPill(.red))
            } else {
                Button(L10n.save) {
                    viewModel.add(username: username, password: password)
                }
                .buttonStyle(.toolbarPill)
                .disabled(!isValid)
            }
        }
        .errorMessage($viewModel.error) {
            focusedfield = .username
        }
    }
}
