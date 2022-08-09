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

extension UserDto {
    func profileImageSource(maxWidth: CGFloat, maxHeight: CGFloat) -> ImageSource {
        let scaleWidth = UIScreen.main.scale(maxWidth)
        let scaleHeight = UIScreen.main.scale(maxHeight)
        let profileImageURL = ImageAPI.getUserImageWithRequestBuilder(
            userId: id ?? "",
            imageType: .primary,
            maxWidth: scaleWidth,
            maxHeight: scaleHeight
        ).url

        return ImageSource(url: profileImageURL, blurHash: nil)
    }
}
