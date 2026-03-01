//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct RemoteImageLibrary: PagingLibrary {

    struct Environment: Equatable, WithDefaultValue {
        var includeAllLanguages: Bool = false
        var provider: String?

        static var `default`: Self {
            .init()
        }
    }

    let imageType: ImageType
    let parent: _TitledLibraryParent

    // TODO: wrong ids
    init(imageType: ImageType, itemID: String) {
        self.imageType = imageType
        self.parent = .init(
            displayTitle: imageType.displayTitle,
            libraryID: itemID
        )
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [RemoteImageInfo] {
        var parameters = Paths.GetRemoteImagesParameters()
        parameters.isIncludeAllLanguages = environment.includeAllLanguages
        parameters.providerName = environment.provider
        parameters.type = imageType

        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getRemoteImages(itemID: parent.libraryID, parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.images ?? []
    }
}
