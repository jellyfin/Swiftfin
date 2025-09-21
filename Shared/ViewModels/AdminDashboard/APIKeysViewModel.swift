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
import OrderedCollections

@MainActor
@Stateful
final class APIKeysViewModel: ViewModel {

    // MARK: - Actions

    @CasePathable
    enum Action {
        case refresh
        case create(name: String)
        /// Currently just deletes and creates a new API Key
        case update(key: String)
        case delete(key: String)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .initial)
            case .create, .update, .delete:
                .to(.updating, then: .initial)
            }
        }
    }

    // MARK: - Events

    enum Event {
        case updated
    }

    // MARK: - States

    enum State {
        case initial
        case error
        case updating
        case refreshing
    }

    // MARK: - Published Variables

    @Published
    private(set) var apiKeys: [AuthenticationInfo] = []

    // MARK: - Refresh

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getKeys
        let response = try await userSession.client.send(request)

        guard let items = response.value.items else { return }

        apiKeys = items.sorted { lhs, rhs in
            let lhsName = lhs.appName ?? ""
            let rhsName = rhs.appName ?? ""
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    // MARK: - Create API Key

    @Function(\Action.Cases.create)
    private func _create(_ name: String) async throws {
        let request = Paths.createKey(app: name)
        try await userSession.client.send(request)

        /// API does not return the new key so a full refresh is required.
        /// There is no API to return a single API Key.
        try await _refresh()

        events.send(.updated)
    }

    // MARK: - Update API Key

    @Function(\Action.Cases.update)
    private func _update(_ key: String) async throws {
        guard let apiKey = apiKeys.first(where: { $0.accessToken == key }), let keyName = apiKey.appName else {
            throw JellyfinAPIError("API key not found")
        }

        let deleteRequest = Paths.revokeKey(key: key)
        try await userSession.client.send(deleteRequest)

        let createRequest = Paths.createKey(app: keyName)
        try await userSession.client.send(createRequest)

        /// API does not return the new key so a full refresh is required.
        /// There is no API to return a single API Key.
        try await _refresh()

        events.send(.updated)
    }

    // MARK: - Delete API Key

    @Function(\Action.Cases.delete)
    private func _delete(_ key: String) async throws {
        guard let apiKey = apiKeys.first(where: { $0.accessToken == key }) else {
            throw JellyfinAPIError("API key not found")
        }

        let request = Paths.revokeKey(key: key)
        try await userSession.client.send(request)

        apiKeys.removeAll(where: { $0.accessToken == key })

        events.send(.updated)
    }
}
