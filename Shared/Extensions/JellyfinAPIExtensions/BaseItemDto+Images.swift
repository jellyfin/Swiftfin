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

extension BaseItemDto {

    // MARK: Item Images

    func imageURL(
        _ type: ImageType,
        maxWidth: Int
    ) -> URL {
        _imageURL(type, maxWidth: maxWidth, itemID: id ?? "")
    }

    func imageURL(
        _ type: ImageType,
        maxWidth: CGFloat
    ) -> URL {
        _imageURL(type, maxWidth: Int(maxWidth), itemID: id ?? "")
    }

    func blurHash(_ type: ImageType) -> String? {
        guard type != .logo else { return nil }
        if let tag = imageTags?[type.rawValue], let taggedBlurHash = imageBlurHashes?[type]?[tag] {
            return taggedBlurHash
        } else if let firstBlurHash = imageBlurHashes?[type]?.values.first {
            return firstBlurHash
        }

        return nil
    }

    func imageSource(_ type: ImageType, maxWidth: Int) -> ImageSource {
        _imageSource(type, maxWidth: maxWidth)
    }

    func imageSource(_ type: ImageType, maxWidth: CGFloat) -> ImageSource {
        _imageSource(type, maxWidth: Int(maxWidth))
    }

    // MARK: Series Images

    func seriesImageURL(_ type: ImageType, maxWidth: Int) -> URL {
        _imageURL(type, maxWidth: maxWidth, itemID: seriesId ?? "")
    }

    func seriesImageURL(_ type: ImageType, maxWidth: CGFloat) -> URL {
        _imageURL(type, maxWidth: Int(maxWidth), itemID: seriesId ?? "")
    }

    func seriesImageSource(_ type: ImageType, maxWidth: Int) -> ImageSource {
        let url = _imageURL(type, maxWidth: maxWidth, itemID: seriesId ?? "")
        return ImageSource(url: url, blurHash: nil)
    }

    func seriesImageSource(_ type: ImageType, maxWidth: CGFloat) -> ImageSource {
        seriesImageSource(type, maxWidth: Int(maxWidth))
    }

    // MARK: Fileprivate

    fileprivate func _imageURL(
        _ type: ImageType,
        maxWidth: Int,
        itemID: String
    ) -> URL {
        let scaleWidth = UIScreen.main.scale(maxWidth)
        let tag = imageTags?[type.rawValue]
        return ImageAPI.getItemImageWithRequestBuilder(
            itemId: itemID,
            imageType: type,
            maxWidth: scaleWidth,
            tag: tag
        ).url
    }

    fileprivate func _imageSource(_ type: ImageType, maxWidth: Int) -> ImageSource {
        let url = _imageURL(type, maxWidth: maxWidth, itemID: id ?? "")
        let blurHash = blurHash(type)
        return ImageSource(url: url, blurHash: blurHash)
    }
}
