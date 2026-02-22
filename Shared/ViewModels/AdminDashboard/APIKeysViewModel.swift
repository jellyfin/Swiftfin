//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class APIKeysViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case create(name: String)
        case replace(key: AuthenticationInfo)
        case delete(key: AuthenticationInfo)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .initial)
            case .create, .replace, .delete:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
    }

    enum Event {
        case createdKey
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    @Published
    private(set) var apiKeys: [AuthenticationInfo] = []

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

    @Function(\Action.Cases.create)
    private func _create(_ name: String) async throws {
        let request = Paths.createKey(app: name)
        try await userSession.client.send(request)

        /// API does not return the new key so a full refresh is required.
        /// There is no API to return a single API Key.
        try await _refresh()

        events.send(.createdKey)
    }

    @Function(\Action.Cases.replace)
    private func _replace(_ key: AuthenticationInfo) async throws {
        guard let appName = key.appName else {
            logger.error("App name is nil")
            throw ErrorMessage(L10n.unknownError)
        }

        try await _delete(key)
        try await _create(appName)
    }

    @Function(\Action.Cases.delete)
    private func _delete(_ key: AuthenticationInfo) async throws {
        guard let accessToken = key.accessToken else {
            logger.error("Access token is nil")
            throw ErrorMessage(L10n.unknownError)
        }

        let request = Paths.revokeKey(key: accessToken)
        try await userSession.client.send(request)

        apiKeys.removeFirst(equalTo: key)
    }
}
