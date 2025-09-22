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
final class DeviceDetailViewModel: ViewModel {

    @CasePathable
    enum Action {
        case setCustomName(String)

        var transition: Transition {
            switch self {
            case .setCustomName:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
    }

    enum Event {
        case error
        case updatedCustomName
    }

    @Published
    private(set) var device: DeviceInfoDto

    init(device: DeviceInfoDto) {
        self.device = device
    }

    @Function(\Action.Cases.setCustomName)
    private func _setCustomName(_ newName: String) async throws {
        guard let id = device.id else { return }

        let request = Paths.updateDeviceOptions(id: id, .init(customName: newName))
        try await userSession.client.send(request)

        device.customName = newName
        events.send(.updatedCustomName)
    }
}
