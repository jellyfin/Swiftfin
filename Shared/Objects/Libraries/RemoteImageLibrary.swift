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
    let parent: TitledLibraryParent

    init(imageType: ImageType, itemID: String) {
        self.imageType = imageType
        self.parent = .init(displayTitle: imageType.displayTitle, id: itemID)
    }

    func retrievePage(
        environment: Environment,
        pageState: LibraryPageState
    ) async throws -> [RemoteImageInfo] {
        guard let itemID = parent.id else { return [] }

        var parameters = Paths.GetRemoteImagesParameters()
        parameters.isIncludeAllLanguages = environment.includeAllLanguages
        parameters.limit = pageState.pageSize
        parameters.providerName = environment.provider
        parameters.startIndex = pageState.pageOffset
        parameters.type = imageType

        let request = Paths.getRemoteImages(itemID: itemID, parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.images ?? []
    }
}
