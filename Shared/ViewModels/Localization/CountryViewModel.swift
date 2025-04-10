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

final class CountryViewModel: ViewModel, Stateful {

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
    private(set) var countries: Set<CountryInfo> = []

    @Published
    var state: State = .initial

    private var currentRefreshTask: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            currentRefreshTask?.cancel()

            currentRefreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    self.countries = []

                    let serverCountries = try await getCountries()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.countries.insert(contentsOf: serverCountries)
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

    // MARK: - Fetch Countries

    private func getCountries() async throws -> [CountryInfo] {
        let request = Paths.getCountries
        let response = try await userSession.client.send(request)

        return response.value
    }
}
