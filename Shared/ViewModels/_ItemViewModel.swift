//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@Stateful
class _ItemViewModel: ViewModel, WithRefresh {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            switch self {
            case .refresh:
                .to(.refreshing, then: .content)
            }
        }
    }

    enum State: Hashable {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var item: BaseItemDto = .init()
    @Published
    private(set) var playButtonItem: BaseItemDto? {
        willSet {
            selectedMediaSource = newValue?.mediaSources?.first
        }
    }

    @Published
    var selectedMediaSource: MediaSourceInfo?

    init(id: String) {
        self.item = .init(id: id)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let newItem = try await item.getFullItem(userSession: userSession)
        item = newItem

        if item.type == .series {
            playButtonItem = try await getNextUp(seriesID: item.id)
        } else {
            playButtonItem = newItem
        }
    }

    private func getNextUp(seriesID: String?) async throws -> BaseItemDto? {
        var parameters = Paths.GetNextUpParameters()
        parameters.seriesID = seriesID
        parameters.userID = userSession.user.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }
}
