//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ResumeItemsLibrary: BaseItemKindLibrary {

    let mediaTypes: [MediaType]?
    let itemTypes: [BaseItemKind]
    let parent: TitledLibraryParent
    let parentID: String?
    let searchTerm: String?

    var libraryItemTypes: [BaseItemKind] {
        itemTypes.isEmpty ? (mediaTypes ?? [.video]).flatMap(\.supportedLibraryItemTypes) : itemTypes
    }

    init(
        mediaTypes: [MediaType]? = [.video],
        itemTypes: [BaseItemKind] = [],
        parent: TitledLibraryParent = .init(displayTitle: L10n.continue, id: "continue-watching"),
        parentID: String? = nil,
        searchTerm: String? = nil
    ) {
        self.mediaTypes = mediaTypes
        self.itemTypes = itemTypes
        self.parent = parent
        self.parentID = parentID
        self.searchTerm = searchTerm
    }

    func shouldRefreshForUserDataChange(environment: Empty) -> Bool {
        true
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        var parameters = Paths.GetResumeItemsParameters()
        parameters.enableUserData = true
        parameters.fields = PosterSubtitleField.itemFields
        parameters.includeItemTypes = itemTypes.isEmpty ? nil : itemTypes
        parameters.limit = pageState.pageSize
        parameters.mediaTypes = mediaTypes
        parameters.parentID = parentID
        parameters.searchTerm = searchTerm
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }

    func includes(_ element: ItemEntry, environment: Empty) -> Bool {
        element.item.confirmedUserData?.matches([.isResumable]) != false
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
