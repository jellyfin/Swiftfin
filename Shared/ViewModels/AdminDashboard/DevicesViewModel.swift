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
import SwiftUI

@MainActor
@Stateful
final class DevicesViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case delete(ids: [String])

        var transition: Transition {
            switch self {
            case .refresh:
                .loop(.refreshing, whenBackground: .refreshing)
            case .delete:
                .background(.deleting)
            }
        }
    }

    enum BackgroundState {
        case deleting
        case refreshing
    }

    enum Event {
        case error(JellyfinAPIError)
        case deleted
    }

    enum State {
        case initial
        case refreshing
        case error
    }

    @Published
    private(set) var devices: [DeviceInfoDto] = []

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        try await loadDevices()
    }

    @Function(\Action.Cases.delete)
    private func _delete(_ ids: [String]) async throws {
        try await deleteDevices(ids: ids)
        events.send(.deleted)
    }

    private func loadDevices() async throws {
        let request = Paths.getDevices()
        let response = try await userSession.client.send(request)

        guard let devices = response.value.items else {
            return
        }

        self.devices = devices.sorted(using: \.dateLastActivity)
            .reversed()
    }

    private func deleteDevice(id: String) async throws {
        // Don't allow self-deletion
        guard id != userSession.client.configuration.deviceID else {
            return
        }

        let request = Paths.deleteDevice(id: id)
        try await userSession.client.send(request)

        try await loadDevices()
    }

    private func deleteDevices(ids: [String]) async throws {
        guard ids.isNotEmpty else {
            return
        }

        // Don't allow self-deletion
        let deviceIdsToDelete = ids.filter { $0 != userSession.client.configuration.deviceID }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for deviceId in deviceIdsToDelete {
                group.addTask {
                    try await self.deleteDevice(id: deviceId)
                }
            }

            try await group.waitForAll()
        }

        try await loadDevices()
    }
}
