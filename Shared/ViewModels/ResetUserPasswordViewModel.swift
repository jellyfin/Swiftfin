//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class ResetUserPasswordViewModel: ViewModel, Eventful, Stateful {

    // MARK: - Event

    enum Event {
        case error(ErrorMessage)
        case success
    }

    // MARK: - Action

    enum Action: Equatable {
        case cancel
        case reset(current: String, new: String)
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case resetting
    }

    // MARK: - Published Variables

    @Published
    var state: State = .initial
    let userID: String

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var resetTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Initializer

    init(userID: String) {
        self.userID = userID
    }

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            resetTask?.cancel()

            return .initial
        case let .reset(current, new):
            resetTask = Task {
                do {
//                    try await Task.sleep(nanoseconds: 5_000_000_000)

                    try await reset(current: current, new: new)

                    await MainActor.run {
                        self.eventSubject.send(.success)
                        self.state = .initial
                    }
                } catch is CancellationError {
                    // cancel doesn't matter
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                        self.state = .initial
                    }
                }
            }
            .asAnyCancellable()

            return .resetting
        }
    }

    private func reset(current: String, new: String) async throws {
        let body = UpdateUserPassword(currentPw: current, newPw: new)
        let request = Paths.updateUserPassword(userID: userID, body)

        try await userSession.client.send(request)
    }
}
