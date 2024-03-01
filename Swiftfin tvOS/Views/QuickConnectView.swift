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
    var viewModel: UserSignInViewModel
    @Binding
    var isPresentingQuickConnect: Bool

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
        switch viewModel.quickConnectStatus {
        case let .awaitingAuthentication(code):
            quickConnectWaitingAuthentication(quickConnectCode: code)
        case nil, .fetchingSecret, .authorized:
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
        .onAppear {
            Task {
                await viewModel.signInWithQuickConnect()
            }
        }
        .onDisappear {
            viewModel.stopQuickConnectAuthCheck()
        }
    }
}
