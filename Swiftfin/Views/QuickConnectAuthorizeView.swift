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

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @FocusState
    private var isCodeFocused: Bool

    @StateObject
    private var viewModel: QuickConnectAuthorizeViewModel

    @State
    private var code: String = ""
    @State
    private var isPresentingSuccess: Bool = false

    init(user: UserDto) {
        self._viewModel = StateObject(wrappedValue: QuickConnectAuthorizeViewModel(user: user))
    }

    @ViewBuilder
    private var loginUserRow: some View {
        HStack {
            if let userSession = viewModel.userSession {
                UserProfileImage(
                    userID: viewModel.user.id,
                    source: viewModel.user.profileImageSource(
                        client: userSession.client,
                        maxWidth: 120
                    )
                )
                .frame(width: 50, height: 50)
            }

            Text(viewModel.user.name ?? L10n.unknown)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()
        }
    }

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
                Button(role: .cancel) {
                    viewModel.cancel()
                    isCodeFocused = true
                } label: {
                    Text(L10n.cancel)
                        .frame(maxWidth: .infinity)
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .fontWeight(.semibold)
                .backport
                .buttonStyle(.glassProminent.shadow(false))
                .controlSize(.large)
            } else {
                Button {
                    viewModel.authorize(code: code)
                } label: {
                    Text(L10n.authorize)
                        .frame(maxWidth: .infinity)
                }
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .fontWeight(.semibold)
                .backport
                .buttonStyle(.glassProminent.shadow(false))
                .tint(accentColor)
                .controlSize(.large)
                .disabled(code.count != 6 || viewModel.state == .authorizing)
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
