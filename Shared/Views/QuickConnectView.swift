//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct QuickConnectView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: QuickConnect

    init(quickConnect: QuickConnect) {
        self.viewModel = quickConnect
    }

    private func pollingView(code: String) -> some View {
        VStack(spacing: 20) {
            BulletedList(spacing: 16) {
                Text(L10n.quickConnectStep1)

                Text(L10n.quickConnectStep2)

                Text(L10n.quickConnectStep3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(code)
                .tracking(10)
                .font(.largeTitle)
                .monospacedDigit()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .edgePadding()
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .authenticated, .idle, .retrievingCode:
                ProgressView()
            case let .polling(code):
                pollingView(code: code)
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .edgePadding()
        .navigationTitle(L10n.quickConnect)
        .refreshable {
            viewModel.start()
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        #endif
        .onFirstAppear {
                viewModel.start()
            }
            .onDisappear {
                viewModel.stop()
            }
    }
}
