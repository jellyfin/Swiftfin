//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ResumeItemsLibrary: PagingLibrary {

    let mediaTypes: [MediaType]
    let parent: _TitledLibraryParent = .init(
        displayTitle: "Continue Watching",
        libraryID: "continue-watching"
    )

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.userID = pageState.userSession.user.id
        parameters.enableUserData = true
        parameters.mediaTypes = mediaTypes

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }

    func onItemUserDataChanged(
        viewModel: PagingLibraryViewModel<ResumeItemsLibrary>,
        userData: UserItemDataDto
    ) {
        guard let itemID = userData.itemID else { return }

        if userData.isPlayed == true {
            viewModel.elements.remove(id: itemID)
            return
        }

        guard !viewModel.elements.ids.contains(itemID) else { return }
        guard userData.playbackPosition.map({ $0 > .zero }) == true else { return }

        viewModel.scheduleRefreshForItemUserData(minimumInterval: 30)
    }
}
