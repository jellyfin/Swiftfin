//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct QuickConnectAuthorizeView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @FocusState
    private var isCodeFocused: Bool

    @State
    private var code: String = ""
    @State
    private var errorMessage: String = ""
    @State
    private var isAuthorized: Bool = false
    @State
    private var isPresentingError: Bool = false

    @StateObject
    private var viewModel = QuickConnectAuthorizeViewModel()

    var body: some View {
        Form {
            Section {
                TextField(L10n.quickConnectCode, text: $code)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.isLoading)
                    .focused($isCodeFocused)

                Button {
                    viewModel.send(.authorize(code))
                } label: {
                    L10n.authorize.text
                        .font(.callout)
                        .disabled(code.count != 6 || viewModel.state == .authorizing)
                }
            } footer: {
                Text("Enter the 6 digit code from your other device.")
            }
        }
        .navigationTitle(L10n.quickConnect.text)
        .onReceive(viewModel.events) { event in
            switch event {
            case .authorized:
                isAuthorized = true
            case let .error(error):
                self.errorMessage = error.localizedDescription
                self.isPresentingError = true
            }
        }
        .alert(
            L10n.error,
            isPresented: $isPresentingError
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(errorMessage)
        }
        .alert(
            L10n.quickConnect,
            isPresented: $isAuthorized
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.pop()
            }
        } message: {
            L10n.quickConnectSuccessMessage.text
        }
        .onFirstAppear {
            isCodeFocused = true
        }
        .topBarTrailing {
            if viewModel.state == .authorizing {
                ProgressView()
            }
        }
    }
}
