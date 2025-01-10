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

final class ParentalRatingsViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    private(set) var parentalRatings: [ParentalRating] = []

    @Published
    final var state: State = .initial

    private var currentRefreshTask: AnyCancellable?

    var hasNoResults: Bool {
        parentalRatings.isEmpty
    }

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            currentRefreshTask?.cancel()

            currentRefreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let parentalRatings = try await getParentalRatings()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.parentalRatings = parentalRatings
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Fetch Parental Ratings

    private func getParentalRatings() async throws -> [ParentalRating] {
        let request = Paths.getParentalRatings
        let response = try await userSession.client.send(request)

        return response.value
    }
}
