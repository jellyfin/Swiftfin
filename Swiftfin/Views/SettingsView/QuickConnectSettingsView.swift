//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct QuickConnectSettingsView: View {

    @ObservedObject
    var viewModel: QuickConnectSettingsViewModel

    @State
    private var code: String = ""
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false
    @State
    private var isPresentingSuccess: Bool = false

    var body: some View {
        Form {
            Section {
                TextField(L10n.quickConnectCode, text: $code)
                    .keyboardType(.numberPad)
                    .disabled(viewModel.isLoading)

                Button {
                    Task {
                        do {
                            try await viewModel.authorize(code: code)
                            isPresentingSuccess = true
                        } catch {
                            self.error = error
                            isPresentingError = true
                        }
                    }
                } label: {
                    L10n.authorize.text
                        .font(.callout)
                        .disabled(code.count != 6 || viewModel.isLoading)
                }
            }
        }
        .navigationTitle(L10n.quickConnect.text)
        .alert(
            L10n.error,
            isPresented: $isPresentingError
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            Text(error?.localizedDescription ?? .emptyDash)
        }
        .alert(
            L10n.quickConnect,
            isPresented: $isPresentingSuccess
        ) {
            Button(L10n.dismiss, role: .cancel)
        } message: {
            L10n.quickConnectSuccessMessage.text
        }
    }
}
