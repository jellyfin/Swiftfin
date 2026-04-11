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
import SwiftUI

@MainActor
@Stateful
final class ServerConfigurationViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case update(ServerConfiguration)

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.initial, then: .content)
            case .update:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    private(set) var systemInfo: SystemInfo?
    @Published
    private(set) var systemStorage: SystemStorageDto?
    @Published
    private(set) var itemCounts: ItemCounts?

    @Published
    private(set) var configuration: ServerConfiguration?

    // MARK: - Refresh

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        self.systemInfo = try await getSystemInfo()
        self.systemStorage = try await getSystemStorage()
        self.configuration = try await getConfiguration()
        self.itemCounts = try await getItemCounts()
    }

    private func getSystemInfo() async throws -> SystemInfo {
        let request = Paths.getSystemInfo
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func getSystemStorage() async throws -> SystemStorageDto? {
        let request = Paths.getSystemStorage
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func getConfiguration() async throws -> ServerConfiguration {
        let request = Paths.getConfiguration
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func getItemCounts() async throws -> ItemCounts? {
        let request = Paths.getItemCounts(userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        return response.value
    }

    // MARK: - Update Configuration

    @Function(\Action.Cases.update)
    private func _update(_ newConfiguration: ServerConfiguration) async throws {
        let request = Paths.updateConfiguration(newConfiguration)
        _ = try await userSession.client.send(request)

        self.configuration = newConfiguration
        try await _refresh()

        events.send(.updated)
    }
}
