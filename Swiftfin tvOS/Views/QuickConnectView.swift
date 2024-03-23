//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct QuickConnectView: View {
    @ObservedObject
    var viewModel: QuickConnectViewModel
    @Binding
    var isPresentingQuickConnect: Bool
    // Once the auth secret is fetched, run this and dismiss this view
    var signIn: @MainActor (_: String) -> Void

    func quickConnectWaitingAuthentication(quickConnectCode: String) -> some View {
        Text(quickConnectCode)
            .tracking(10)
            .font(.title)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
    }

    var quickConnectFailed: some View {
        Label {
            Text("Failed to retrieve quick connect code")
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
        }
    }

    var quickConnectLoading: some View {
        ProgressView()
    }

    @ViewBuilder
    var quickConnectBody: some View {
        switch viewModel.state {
        case let .awaitingAuthentication(code):
            quickConnectWaitingAuthentication(quickConnectCode: code)
        case .initial, .fetchingSecret, .authenticated:
            quickConnectLoading
        case .error:
            quickConnectFailed
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            L10n.quickConnect.text
                .font(.title3)
                .fontWeight(.semibold)

            Group {
                VStack(alignment: .leading, spacing: 20) {
                    L10n.quickConnectStep1.text

                    L10n.quickConnectStep2.text

                    L10n.quickConnectStep3.text
                }
                .padding(.vertical)

                quickConnectBody
            }
            .padding(.bottom)

            Button {
                isPresentingQuickConnect = false
            } label: {
                L10n.close.text
                    .frame(width: 400, height: 75)
            }
            .buttonStyle(.plain)
        }
        .onChange(of: viewModel.state) { newState in
            if case let .authenticated(secret: secret) = newState {
                signIn(secret)
                isPresentingQuickConnect = false
            }
        }
        .onAppear {
            viewModel.send(.startQuickConnect)
        }
        .onDisappear {
            viewModel.send(.cancelQuickConnect)
        }
    }
}
