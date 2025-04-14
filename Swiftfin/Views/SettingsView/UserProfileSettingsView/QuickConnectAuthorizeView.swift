//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct QuickConnectAuthorizeView: View {

    // MARK: - Dismiss Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    @FocusState
    private var isCodeFocused: Bool

    // MARK: - State & Environment Objects

    @StateObject
    private var viewModel: QuickConnectAuthorizeViewModel

    // MARK: - Quick Connect Variables

    @State
    private var code: String = ""

    // MARK: - Dialog State

    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Initialize

    init(user: UserDto) {
        self._viewModel = StateObject(wrappedValue: QuickConnectAuthorizeViewModel(user: user))
    }

    // MARK: Display the User Being Authenticated

    @ViewBuilder
    private var loginUserRow: some View {
        HStack {
            UserProfileImage(
                userID: viewModel.user.id,
                source: viewModel.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120
                )
            )
            .frame(width: 50, height: 50)

            Text(viewModel.user.name ?? L10n.unknown)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                loginUserRow
            } header: {
                Text(L10n.user)
            } footer: {
                Text(L10n.quickConnectUserDisclaimer)
            }

            Section {
                TextField(L10n.quickConnectCode, text: $code)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.state == .authorizing)
                    .focused($isCodeFocused)
            } footer: {
                Text(L10n.quickConnectCodeInstruction)
            }

            if viewModel.state == .authorizing {
                ListRowButton(L10n.cancel, role: .cancel) {
                    viewModel.send(.cancel)
                    isCodeFocused = true
                }
            } else {
                ListRowButton(L10n.authorize) {
                    viewModel.send(.authorize(code: code))
                }
                .disabled(code.count != 6 || viewModel.state == .authorizing)
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
                .opacity(code.count != 6 ? 0.5 : 1)
            }
        }
        .interactiveDismissDisabled(viewModel.state == .authorizing)
        .navigationBarBackButtonHidden(viewModel.state == .authorizing)
        .navigationTitle(L10n.quickConnect.text)
        .onFirstAppear {
            isCodeFocused = true
        }
        .onChange(of: code) { newValue in
            code = String(newValue.prefix(6))
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .authorized:
                UIDevice.feedback(.success)

                isPresentingSuccess = true
            case let .error(eventError):
                UIDevice.feedback(.error)

                error = eventError
            }
        }
        .topBarTrailing {
            if viewModel.state == .authorizing {
                ProgressView()
            }
        }
        .alert(
            L10n.quickConnect,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                dismiss()
            }
        } message: {
            L10n.quickConnectSuccessMessage.text
        }
        .errorMessage($error) {
            isCodeFocused = true
        }
    }
}
