//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct QuickConnectView: View {
    @EnvironmentObject
    private var router: QuickConnectCoordinator.Router

    @ObservedObject
    var viewModel: QuickConnectViewModel

    // Once the auth secret is fetched, run this and dismiss this view
    var signIn: @MainActor (_: String) -> Void

    func quickConnectWaitingAuthentication(quickConnectCode: String) -> some View {
        Text(quickConnectCode)
            .tracking(10)
            .font(.largeTitle)
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
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
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
        VStack(alignment: .leading, spacing: 20) {
            L10n.quickConnectStep1.text

            L10n.quickConnectStep2.text

            L10n.quickConnectStep3.text
                .padding(.bottom)

            quickConnectBody

            Spacer()
        }
        .padding(.horizontal)
        .navigationTitle(L10n.quickConnect)
        .onChange(of: viewModel.state) { newState in
            if case let .authenticated(secret: secret) = newState {
                signIn(secret)
                router.dismissCoordinator()
            }
        }
        .onAppear {
            viewModel.send(.startQuickConnect)
        }
        .onDisappear {
            viewModel.send(.cancelQuickConnect)
        }
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
