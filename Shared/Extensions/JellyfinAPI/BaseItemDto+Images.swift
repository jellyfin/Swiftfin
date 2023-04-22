//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import UIKit

extension BaseItemDto {

    // MARK: Item Images

    func imageURL(
        _ type: ImageType,
        maxWidth: Int? = nil,
        maxHeight: Int? = nil
    ) -> URL {
        _imageURL(type, maxWidth: maxWidth, maxHeight: maxHeight, itemID: id ?? "")
    }

    func imageURL(
        _ type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> URL {
        _imageURL(type, maxWidth: Int(maxWidth), maxHeight: Int(maxHeight), itemID: id ?? "")
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

    func imageSource(_ type: ImageType, maxWidth: Int? = nil, maxHeight: Int? = nil) -> ImageSource {
        _imageSource(type, maxWidth: maxWidth, maxHeight: maxHeight)
    }

    func imageSource(_ type: ImageType, maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) -> ImageSource {
        _imageSource(type, maxWidth: Int(maxWidth), maxHeight: Int(maxHeight))
    }

    // MARK: Series Images

    func seriesImageURL(_ type: ImageType, maxWidth: Int? = nil, maxHeight: Int? = nil) -> URL {
        _imageURL(type, maxWidth: maxWidth, maxHeight: maxHeight, itemID: seriesID ?? "")
    }

    func seriesImageURL(_ type: ImageType, maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) -> URL {
        _imageURL(type, maxWidth: Int(maxWidth), maxHeight: Int(maxHeight), itemID: seriesID ?? "")
    }

    func seriesImageSource(_ type: ImageType, maxWidth: Int? = nil, maxHeight: Int? = nil) -> ImageSource {
        let url = _imageURL(type, maxWidth: maxWidth, maxHeight: maxHeight, itemID: seriesID ?? "")
        return ImageSource(url: url, blurHash: nil)
    }

    func seriesImageSource(_ type: ImageType, maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) -> ImageSource {
        seriesImageSource(type, maxWidth: Int(maxWidth), maxHeight: Int(maxWidth))
    }

    func seriesImageSource(_ type: ImageType, maxWidth: CGFloat) -> ImageSource {
        seriesImageSource(type, maxWidth: Int(maxWidth))
    }

    // MARK: Fileprivate

    fileprivate func _imageURL(
        _ type: ImageType,
        maxWidth: Int?,
        maxHeight: Int?,
        itemID: String
    ) -> URL {
        // TODO: See if the scaling is actually right so that it isn't so big
        let scaleWidth = maxWidth == nil ? nil : UIScreen.main.scale(maxWidth!)
        let scaleHeight = maxHeight == nil ? nil : UIScreen.main.scale(maxHeight!)
        let tag = imageTags?[type.rawValue]

        let client = Container.userSession.callAsFunction().client
        let parameters = Paths.GetItemImageParameters(
            maxWidth: scaleWidth,
            maxHeight: scaleHeight,
            tag: tag
        )

        let request = Paths.getItemImage(
            itemID: itemID,
            imageType: type.rawValue,
            parameters: parameters
        )

        return client.fullURL(with: request)
    }

    fileprivate func _imageSource(_ type: ImageType, maxWidth: Int?, maxHeight: Int?) -> ImageSource {
        let url = _imageURL(type, maxWidth: maxWidth, maxHeight: maxHeight, itemID: id ?? "")
        let blurHash = blurHash(type)
        return ImageSource(url: url, blurHash: blurHash)
    }
}

fileprivate extension Int {
    init?(_ source: CGFloat?) {
        if let source = source {
            self.init(source)
        } else {
            return nil
        }
    }
}
