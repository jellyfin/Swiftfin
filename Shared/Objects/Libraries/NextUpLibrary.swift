//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct NextUpLibrary: PagingLibrary {

    struct Environment: WithDefaultValue {
        let enableRewatching: Bool
        let maxNextUp: TimeInterval

        static var `default`: Self {
            .init(
                enableRewatching: false,
                maxNextUp: 0
            )
        }
    }

    let parent: _TitledLibraryParent = .init(
        displayTitle: L10n.nextUp,
        libraryID: "next-up"
    )

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetNextUpParameters()
        parameters.enableRewatching = environment.enableRewatching
        parameters.enableResumable = false
        parameters.enableUserData = true

        if environment.maxNextUp > 0 {
            parameters.nextUpDateCutoff = Date.now.addingTimeInterval(-environment.maxNextUp)
        }

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    func onItemUserDataChanged(
        viewModel: PagingLibraryViewModel<NextUpLibrary>,
        userData: UserItemDataDto
    ) {
        guard let itemID = userData.itemID else { return }

        if viewModel.elements.ids.contains(itemID) {
            viewModel.scheduleRefreshForItemUserData(minimumInterval: 3)
            return
        }

        let canAffectMembership = userData.playbackPosition.map { $0 > .zero } == true
            || userData.isPlayed != nil

        guard canAffectMembership else { return }

        viewModel.scheduleRefreshForItemUserData(minimumInterval: 30)
    }
}
