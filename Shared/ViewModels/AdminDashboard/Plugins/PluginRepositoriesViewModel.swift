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
@Stateful
final class PluginRepositoriesViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case add(RepositoryInfo)
        case remove(RepositoryInfo)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
                    .whenBackground(.refreshing)

            case .add, .remove:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case refreshing
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case content
        case error
        case initial
    }

    @Published
    private(set) var repositories: [RepositoryInfo] = []

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getRepositories
        let response = try await send(request)

        repositories = response.value
    }

    @Function(\Action.Cases.add)
    private func _add(_ repository: RepositoryInfo) async throws {
        try await updateRepositories(repositories.appending(repository))
    }

    @Function(\Action.Cases.remove)
    private func _remove(_ repository: RepositoryInfo) async throws {
        try await updateRepositories(repositories.filtering { $0 == repository })
    }

    private func updateRepositories(_ updatedRepositories: [RepositoryInfo]) async throws {
        let request = Paths.setRepositories(updatedRepositories)
        try await send(request)

        repositories = updatedRepositories

        events.send(.updated)
    }
}
