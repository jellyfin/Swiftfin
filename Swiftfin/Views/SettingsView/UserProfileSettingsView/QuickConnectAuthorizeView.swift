//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

struct QuickConnectAuthorizeView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @FocusState
    private var isCodeFocused: Bool

    @State
    private var code: String = ""
    @State
    private var error: Error? = nil
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    @StateObject
    private var viewModel = QuickConnectAuthorizeViewModel()

    var body: some View {
        Form {
            Section {
                TextField(L10n.quickConnectCode, text: $code)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.state == .authorizing)
                    .focused($isCodeFocused)
            } footer: {
                Text("Enter the 6 digit code from your other device.")
            }

            if viewModel.state == .authorizing {
                ListRowButton(L10n.cancel) {
                    viewModel.send(.cancel)
                    isCodeFocused = true
                }
                .foregroundStyle(.red, .red.opacity(0.2))
            } else {
                ListRowButton(L10n.authorize) {
                    viewModel.send(.authorize(code))
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
                isPresentingError = true
            }
        }
        .topBarTrailing {
            if viewModel.state == .authorizing {
                ProgressView()
            }
        }
        .alert(
            L10n.error.text,
            isPresented: $isPresentingError,
            presenting: error
        ) { _ in
            Button(L10n.dismiss, role: .destructive) {
                isCodeFocused = true
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert(
            L10n.quickConnect,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel) {
                router.pop()
            }
        } message: {
            L10n.quickConnectSuccessMessage.text
        }
    }
}
