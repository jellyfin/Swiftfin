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
    var viewModel: UserSignInViewModel

    func quickConnectWaitingAuthentication(quickConnectCode: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            L10n.quickConnectStep1.text

            L10n.quickConnectStep2.text

            L10n.quickConnectStep3.text
                .padding(.bottom)

            Text(quickConnectCode)
                .tracking(10)
                .font(.largeTitle)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer()
        }
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
        switch viewModel.quickConnectStatus {
        case let .awaitingAuthentication(_, code):
            quickConnectWaitingAuthentication(quickConnectCode: code)
        case nil, .fetchingSecret:
            quickConnectLoading
        case .fetchingSecretFailed:
            quickConnectFailed
        }
    }

    var body: some View {
        quickConnectBody
            .padding(.horizontal)
            .navigationTitle(L10n.quickConnect)
            .onAppear {
                Task {
                    for await result in viewModel.startQuickConnect() {
                        guard let secret = result.secret else { continue }
                        try? await viewModel.signIn(quickConnectSecret: secret)
                        router.dismissCoordinator()
                    }
                }
            }
            .onDisappear {
                viewModel.stopQuickConnectAuthCheck()
            }
            .navigationCloseButton {
                router.dismissCoordinator()
            }
    }
}
