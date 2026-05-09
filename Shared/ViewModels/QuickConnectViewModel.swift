//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
final class QuickConnectViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case retrievingCode
        case polling(code: String)
        case authenticated(secret: String)
        case error(Error)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.retrievingCode, .retrievingCode),
                 (.error, .error):
                true
            case let (.polling(l), .polling(r)):
                l == r
            case let (.authenticated(l), .authenticated(r)):
                l == r
            default:
                false
            }
        }
    }

    @Published
    private(set) var state: State = .idle

    private let quickConnect: QuickConnect
    private var task: Task<Void, Never>?

    init(client: JellyfinClient) {
        self.quickConnect = client.quickConnect
    }

    func start() {
        task?.cancel()
        state = .retrievingCode

        task = Task { [quickConnect] in
            do {
                for try await event in quickConnect.connect() {
                    switch event {
                    case let .polling(code: code):
                        state = .polling(code: code)
                    case let .authenticated(secret: secret):
                        state = .authenticated(secret: secret)
                    }
                }
            } catch is CancellationError {
                ()
            } catch {
                state = .error(error)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        state = .idle
    }
}
