//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI

final class ServerActivityDetailViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case refresh
    }

    // MARK: - State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
    }

    // MARK: - Stateful Variables

    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var state: State = .initial

    // MARK: - Published Variables

    @Published
    var log: ActivityLogEntry
    @Published
    var user: UserDto?
    @Published
    var item: BaseItemDto?

    // MARK: - Cancellable

    private var getActivityCancellable: AnyCancellable?

    // MARK: - Initialize

    init(log: ActivityLogEntry, user: UserDto?) {
        self.log = log
        self.user = user
    }

    // MARK: - Respond

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            getActivityCancellable?.cancel()
            getActivityCancellable = Task {
                do {

                    if let itemID = log.itemID {
                        self.item = try await getItem(for: itemID)
                    } else {
                        self.item = nil
                    }

                    if let userID = log.userID {
                        self.user = try await getUser(for: userID)
                    } else {
                        self.user = nil
                    }

                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        }
    }

    // MARK: - Get the Activity's Item

    private func getItem(for itemID: String) async throws -> BaseItemDto? {
        let request = Paths.getItem(itemID: itemID)
        let response = try await userSession.client.send(request)

        return response.value
    }

    // MARK: - Get the Activity's User

    private func getUser(for userID: String) async throws -> UserDto? {
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
