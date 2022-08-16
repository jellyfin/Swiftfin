//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

// MARK: PortraitImageStackable

extension BaseItemPerson: Poster {

    var title: String {
        self.name ?? "--"
    }

    var subtitle: String? {
        self.firstRole
    }

    var showTitle: Bool {
        true
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        let scaleWidth = UIScreen.main.scale(maxWidth)
        let url = ImageAPI.getItemImageWithRequestBuilder(
            itemId: id ?? "",
            imageType: .primary,
            maxWidth: scaleWidth,
            tag: primaryImageTag
        ).url

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
