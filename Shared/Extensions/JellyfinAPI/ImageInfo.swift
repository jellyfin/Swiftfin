//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ImageInfo: @retroactive Identifiable {

    public var id: Int {
        hashValue
    }
}

extension ImageInfo: ItemImageDetail {

    var index: Int? {
        imageIndex
    }

    var language: String? {
        nil
    }

    var provider: String? {
        nil
    }

    var rating: Double? {
        nil
    }

    var ratingVotes: Int? {
        nil
    }

    func imageSource(itemID: String, client: JellyfinClient) -> ImageSource {
        itemImageSource(itemID: itemID, client: client)
    }

    func itemImageSource(itemID: String, client: JellyfinClient) -> ImageSource {
        let parameters = Paths.GetItemImageParameters(
            tag: imageTag,
            imageIndex: imageIndex
        )
        let request = Paths.getItemImage(
            itemID: itemID,
            imageType: imageType?.rawValue ?? "",
            parameters: parameters
        )

        let itemImageURL = client.fullURL(with: request)

        return ImageSource(url: itemImageURL)
    }
}
