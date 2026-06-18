//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ResumeItemsLibrary: BaseItemKindLibrary {

    let mediaTypes: [MediaType]
    let parent: TitledLibraryParent = .init(displayTitle: L10n.continue, id: "continue-watching")

    var libraryItemTypes: [BaseItemKind] {
        mediaTypes.flatMap(\.supportedLibraryItemTypes)
    }

    init(mediaTypes: [MediaType] = [.video]) {
        self.mediaTypes = mediaTypes
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.mediaTypes = mediaTypes
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

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
            viewModel.elements.removeAll { $0.id == itemID }
            return
        }

        let isAlreadyLoaded = viewModel.elements.contains { $0.id == itemID }
        guard !isAlreadyLoaded else { return }
        guard (userData.playbackPositionTicks ?? 0) > 0 else { return }

        viewModel.scheduleRefreshForItemUserData(minimumInterval: 30)
    }
}

private extension MediaType {

    var supportedLibraryItemTypes: [BaseItemKind] {
        switch self {
        case .audio:
            [.audio, .musicAlbum]
        case .video:
            [.episode, .movie, .video]
        case .book:
            [.book]
        case .photo:
            [.photo]
        case .unknown:
            []
        }
    }
}
