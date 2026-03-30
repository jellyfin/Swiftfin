//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class ServerStatisticsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .to(.initial, then: .content)
        }
    }

    enum State {
        case initial
        case content
        case error
    }

    @Published
    private(set) var systemStorage: SystemStorageDto?
    @Published
    private(set) var itemCounts: ItemCounts?

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        self.systemStorage = try await getSystemStorage()
        self.itemCounts = try await getItemCounts()
    }

    private func getSystemStorage() async throws -> SystemStorageDto? {
        let request = Paths.getSystemStorage
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func getItemCounts() async throws -> ItemCounts? {
        let request = Paths.getItemCounts(userID: userSession.user.id)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
