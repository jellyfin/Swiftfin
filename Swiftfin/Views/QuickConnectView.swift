//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct QuickConnectView: View {

    @EnvironmentObject
    private var router: UserSignInCoordinator.Router

    @ObservedObject
    private var viewModel: QuickConnect

    init(quickConnect: QuickConnect) {
        self.viewModel = quickConnect
    }

    private func pollingView(code: String) -> some View {
        Text(code)
            .tracking(10)
            .font(.largeTitle)
            .monospacedDigit()
    }

    #warning("TODO: retry")
    @ViewBuilder
    private func errorView(error: QuickConnect.QuickConnectError) -> some View {
        Text(error.localizedDescription)
    }

    var body: some View {
        WrappedView {
            switch viewModel.state {
            case .idle:
                Color.clear
            case .retrievingCode:
                ProgressView()
            case let .polling(code):
                pollingView(code: code)
            case .authenticated:
                Text("Authenticated")
            case let .error(error):
                errorView(error: error)
            }
        }
        .edgePadding()
        .navigationTitle(L10n.quickConnect)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .navigationBarCloseButton {
            router.popLast()
        }
    }
}
