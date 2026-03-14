//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Logging
import SwiftUI

struct QuickConnectAction {

    let action: (JellyfinClient) async throws -> String

    func callAsFunction(client: JellyfinClient) async throws -> String {
        try await action(client)
    }
}

extension EnvironmentValues {

    @Entry
    var quickConnectAction: QuickConnectAction? = nil
}

struct WithQuickConnect<Content: View>: View {

    @Router
    private var router

    @State
    private var cancellable: AnyCancellable?
    @State
    private var continuation: CheckedContinuation<String, Error>? = nil
    @State
    private var quickConnect: QuickConnect? = nil

    private let content: Content
    private let logger = Logger.swiftfin()

    private func handleQuickConnectState(
        _ state: QuickConnect.State
    ) {
        switch state {
        case let .error(error):
            continuation?.resume(throwing: error)
            self.cancellable = nil
            self.continuation = nil
            self.quickConnect = nil
        case let .authenticated(secret: secret):
            continuation?.resume(returning: secret)
            self.cancellable = nil
            self.continuation = nil
            self.quickConnect = nil
        case .idle:
            continuation?.resume(throwing: CancellationError())
            self.cancellable = nil
            self.continuation = nil
            self.quickConnect = nil
        default: ()
        }
    }

    private func handleQuickConnect(client: JellyfinClient) async throws -> String {
        guard quickConnect == nil else {
            logger.error("QuickConnect action called while one is already active")
            throw ErrorMessage(L10n.unknownError)
        }

        let newQuickConnect = QuickConnect(client: client)
        self.quickConnect = newQuickConnect

        router.route(to: .quickConnect(quickConnect: newQuickConnect))

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            cancellable = newQuickConnect.$state
                .dropFirst()
                .sink(receiveValue: handleQuickConnectState)
        }
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(
                \.quickConnectAction,
                .init(action: handleQuickConnect)
            )
    }
}
