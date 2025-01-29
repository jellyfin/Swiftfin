//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: change to a fullscreen alert-like view instead of a plain modal

struct QuickConnectView: View {

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @ObservedObject
    private var viewModel: QuickConnect

    init(quickConnect: QuickConnect) {
        self.viewModel = quickConnect
    }

    private func pollingView(code: String) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            BulletedList {
                L10n.quickConnectStep1.text
                    .padding(.bottom)
                L10n.quickConnectStep2.text
                    .padding(.bottom)
                L10n.quickConnectStep3.text
                    .padding(.bottom)
            }

            Text(code)
                .tracking(10)
                .font(.largeTitle)
                .monospacedDigit()
                .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .edgePadding()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .idle, .authenticated:
                Color.clear
            case .retrievingCode:
                ProgressView()
            case let .polling(code):
                pollingView(code: code)
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.start()
                    }
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .edgePadding()
        .navigationTitle(L10n.quickConnect)
        .onFirstAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
    }
}
