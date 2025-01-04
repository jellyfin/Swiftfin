//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI
import OrderedCollections
import UIKit

private let DefaultPageSize = 50

class RemoteImageInfoViewModel: PagingLibraryViewModel<RemoteImageInfo> {

    @Published
    var item: BaseItemDto

    @Published
    var imageType: ImageType

    @Published
    var includeAllLanguages: Bool

    init(
        item: BaseItemDto,
        imageType: ImageType,
        includeAllLanguages: Bool = false,
        pageSize: Int = DefaultPageSize
    ) {
        self.item = item
        self.imageType = imageType
        self.includeAllLanguages = includeAllLanguages
        super.init(parent: nil, pageSize: pageSize)
    }

    override func get(page: Int) async throws -> [RemoteImageInfo] {
        guard let itemID = item.id else { return [] }

        let startIndex = page * pageSize
        let parameters = Paths.GetRemoteImagesParameters(
            type: imageType,
            startIndex: startIndex,
            limit: pageSize,
            isIncludeAllLanguages: includeAllLanguages
        )

        let request = Paths.getRemoteImages(itemID: itemID, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.images ?? []
    }
}
