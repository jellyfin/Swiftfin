//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct QuickConnectAuthorizeView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    @FocusState
    private var isCodeFocused: Bool

    @Router
    private var router

    // MARK: - State & Environment Objects

    @StateObject
    private var viewModel: QuickConnectAuthorizeViewModel

    // MARK: - Quick Connect Variables

    @State
    private var code: String = ""

    // MARK: - Dialog State

    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Initialize

    init(user: UserDto) {
        self._viewModel = StateObject(wrappedValue: QuickConnectAuthorizeViewModel(user: user))
    }

    // MARK: Display the User Being Authenticated

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
                Button(L10n.cancel, role: .cancel) {
                    viewModel.cancel()
                    isCodeFocused = true
                }
                .buttonStyle(.primary)
            } else {
                Button(L10n.authorize) {
                    viewModel.authorize(code: code)
                }
                .buttonStyle(.primary)
                .disabled(code.count != 6 || viewModel.state == .authorizing)
                .foregroundStyle(
                    accentColor.overlayColor,
                    accentColor
                )
            }
        }
        .interactiveDismissDisabled(viewModel.state == .authorizing)
        .navigationBarBackButtonHidden(viewModel.state == .authorizing)
        .navigationTitle(L10n.quickConnect)
        .onFirstAppear {
            isCodeFocused = true
        }
        .onChange(of: code) { newValue in
            code = String(newValue.prefix(6))
        }
        .onReceive(viewModel.$error) { error in
            guard error != nil else { return }
            UIDevice.feedback(.error)
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .authorized:
                UIDevice.feedback(.success)
                isPresentingSuccess = true
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
                router.dismiss()
            }
        } message: {
            Text(L10n.quickConnectSuccessMessage)
        }
        .errorMessage($viewModel.error) {
            isCodeFocused = true
        }
    }
}
