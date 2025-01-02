//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

struct QuickConnectAuthorizeView: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus Fields

    @FocusState
    private var isCodeFocused: Bool

    // MARK: - State & Environment Objects

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = QuickConnectAuthorizeViewModel()

    // MARK: - Quick Connect Variables

    @State
    private var code: String = ""

    // MARK: - Dialog State

    @State
    private var isPresentingSuccess: Bool = false

    // MARK: - Error State

    @State
    private var error: Error? = nil

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                TextField(L10n.quickConnectCode, text: $code)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.state == .authorizing)
                    .focused($isCodeFocused)
            } footer: {
                Text(L10n.quickConnectCodeInstruction)
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
                router.pop()
            }
        } message: {
            L10n.quickConnectSuccessMessage.text
        }
        .errorMessage($error) {
            isCodeFocused = true
        }
    }
}
