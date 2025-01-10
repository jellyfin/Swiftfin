//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class QuickConnectAuthorizeViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case authorized
        case error(JellyfinAPIError)
    }

    // MARK: Action

    enum Action: Equatable {
        case authorize(String)
        case cancel
    }

    // MARK: State

    enum State: Hashable {
        case authorizing
        case initial
    }

    @Published
    var lastAction: Action? = nil
    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var authorizeTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    func respond(to action: Action) -> State {
        switch action {
        case let .authorize(code):
            authorizeTask = Task {

                try? await Task.sleep(nanoseconds: 10_000_000_000)

                do {
                    try await authorize(code: code)

                    await MainActor.run {
                        self.eventSubject.send(.authorized)
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .authorizing
        case .cancel:
            authorizeTask?.cancel()

            return .initial
        }
    }

    private func authorize(code: String) async throws {
        let request = Paths.authorize(code: code)
        let response = try await userSession.client.send(request)

        let decoder = JSONDecoder()
        let isAuthorized = (try? decoder.decode(Bool.self, from: response.value)) ?? false

        if !isAuthorized {
            throw JellyfinAPIError("Authorization unsuccessful")
        }
    }
}
