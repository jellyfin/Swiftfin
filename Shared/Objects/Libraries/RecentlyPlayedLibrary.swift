//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

struct RecentlyPlayedLibrary: BaseItemKindLibrary {

    struct Environment: WithDefaultValue {
        var maxRecentlyPlayed: TimeInterval

        static var `default`: Self {
            .init(maxRecentlyPlayed: Defaults[.Customization.Home.maxRecentlyPlayed])
        }
    }

    let libraryItemTypes: [BaseItemKind] = [.movie, .series]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.recentlyPlayed, id: "recently-played")

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = libraryItemTypes
        parameters.isPlayed = true
        parameters.isRecursive = true
        parameters.limit = pageState.pageSize
        parameters.sortBy = [.datePlayed]
        parameters.sortOrder = [.descending]
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        let items = response.value.items ?? []

        guard environment.maxRecentlyPlayed > 0 else { return items }

        let cutoff = Date.now.addingTimeInterval(-environment.maxRecentlyPlayed)

        return items.filter { ($0.userData?.lastPlayedDate ?? .distantPast) >= cutoff }
    }

    func onItemUserDataChanged(
        viewModel: PagingLibraryViewModel<RecentlyPlayedLibrary>,
        userData: UserItemDataDto
    ) {
        guard userData.isPlayed != nil else { return }

        viewModel.scheduleRefreshForItemUserData(minimumInterval: 30)
    }
}
