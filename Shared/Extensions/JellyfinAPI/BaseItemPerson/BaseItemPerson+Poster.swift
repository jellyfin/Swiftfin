//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import UIKit

extension BaseItemPerson: Poster {

    var subtitle: String? {
        firstRole
    }

    var showTitle: Bool {
        true
    }

    var typeSystemImage: String? {
        "person.fill"
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        let scaleWidth = UIScreen.main.scale(maxWidth)
        let client = Container.userSession().client
        let imageRequestParameters = Paths.GetItemImageParameters(
            maxWidth: scaleWidth,
            tag: primaryImageTag
        )

        let imageRequest = Paths.getItemImage(
            itemID: id ?? "",
            imageType: ImageType.primary.rawValue,
            parameters: imageRequestParameters
        )

        let url = client.fullURL(with: imageRequest)

        var blurHash: String?

        if let tag = primaryImageTag, let taggedBlurHash = imageBlurHashes?.primary?[tag] {
            blurHash = taggedBlurHash
        }

        return ImageSource(url: url, blurHash: blurHash)
    }

    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource] {
        []
    }
}
