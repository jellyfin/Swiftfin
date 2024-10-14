//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class UserAdministrationObserver: ViewModel, Stateful, Identifiable {

    enum Action: Equatable {
        case resetPassword
        case updatePassword(currentPassword: String?, newPassword: String)
        case stopObserving
    }

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
        case updating
        case running
    }

    @Published
    final var state: State = .initial
    @Published
    private(set) var user: UserDto

    private var progressCancellable: AnyCancellable?
    private var cancelCancellable: AnyCancellable?

    var id: String? { user.id }

    init(user: UserDto) {
        self.user = user
    }

    func respond(to action: Action) -> State {
        switch action {
        case .resetPassword:
            if case .running = state {
                return state
            }

            progressCancellable = Task {
                do {
                    try await resetPassword()

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .running

        case let .updatePassword(currentPassword, newPassword):
            if case .running = state {
                return state
            }

            progressCancellable = Task {
                do {
                    try await updatePassword(
                        currentPw: currentPassword,
                        newPw: newPassword
                    )

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .running

        case .stopObserving:
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            return .initial
        }
    }

    // MARK: - Reset Password

    private func resetPassword() async throws {
        guard let userId = user.id else { return }
        let parameters = UpdateUserPassword(isResetPassword: true)
        let updateRequest = Paths.updateUserPassword(userID: userId, parameters)
        try await userSession.client.send(updateRequest)
    }

    // MARK: - Update Password

    private func updatePassword(currentPw: String? = nil, newPw: String) async throws {
        guard let userId = user.id else { return }
        let parameters = UpdateUserPassword(
            currentPw: currentPw,
            newPw: newPw
        )
        let updateRequest = Paths.updateUserPassword(userID: userId, parameters)
        try await userSession.client.send(updateRequest)
    }
}
