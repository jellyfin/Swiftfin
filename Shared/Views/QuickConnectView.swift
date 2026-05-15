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

    @State
    private var code: String? = nil
    @State
    private var error: Error? = nil

    let client: JellyfinClient
    let action: (String) async -> Void

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
            if let error {
                ErrorView(error: error)
            } else if let code {
                pollingView(code: code)
            } else {
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: code)
        .edgePadding()
        .task {
            do {
                for try await event in client.quickConnect.connect() {
                    switch event {
                    case let .polling(code: code):
                        self.code = code
                    case let .authenticated(secret: secret):
                        router.dismiss()
                        await action(secret)
                    }
                }
            } catch {
                self.error = error
            }
        }
        .navigationTitle(L10n.quickConnect)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
        #endif
    }
}
