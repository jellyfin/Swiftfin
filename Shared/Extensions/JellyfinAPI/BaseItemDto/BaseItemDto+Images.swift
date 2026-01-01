//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Factory
import Foundation
import JellyfinAPI
import UIKit

// TODO: figure out what to do about screen scaling with .main being deprecated
//       - maxWidth assume already scaled?
// TODO: change "series" image sources to "parent"
//       - for episodes and extras

extension BaseItemDto {

    // MARK: Item Images

    func imageURL(
        _ type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        quality: Int? = nil
    ) -> URL? {
        _imageURL(
            type,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            itemID: id ?? ""
        )
    }

    // TODO: will server actually only have a single blurhash per type?
    //       - makes `firstBlurHash` redundant
    func blurHash(for type: ImageType) -> BlurHash? {
        guard let blurHashString = blurHashString(for: type) else {
            return nil
        }

        return BlurHash(string: blurHashString)
    }

    func blurHashString(for type: ImageType) -> String? {
        guard type != .logo else { return nil }

        if let tag = imageTags?[type.rawValue], let taggedBlurHash = imageBlurHashes?[type]?[tag] {
            return taggedBlurHash
        } else if let firstBlurHash = imageBlurHashes?[type]?.values.first {
            return firstBlurHash
        }

        return nil
    }

    func imageSource(
        _ type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        quality: Int? = nil
    ) -> ImageSource {
        _imageSource(
            type,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality
        )
    }

    // MARK: Series Images

    /// - Note: Will force the creation of an image source even if it doesn't have a tag, due
    /// to episodes also retrieving series images in some areas. This may cause more 404s.
    func seriesImageURL(
        _ type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        quality: Int? = nil
    ) -> URL? {
        _imageURL(
            type,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            itemID: seriesID ?? "",
            requireTag: false
        )
    }

    /// - Note: Will force the creation of an image source even if it doesn't have a tag, due
    /// to episodes also retrieving series images in some areas. This may cause more 404s.
    func seriesImageSource(
        _ type: ImageType,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        quality: Int? = nil
    ) -> ImageSource {
        let url = _imageURL(
            type,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            itemID: seriesID ?? "",
            requireTag: false
        )

        return ImageSource(
            url: url,
            blurHash: nil
        )
    }

    // MARK: private

    func _imageURL(
        _ type: ImageType,
        maxWidth: CGFloat?,
        maxHeight: CGFloat?,
        quality: Int?,
        itemID: String,
        requireTag: Bool = true
    ) -> URL? {
        let scaleWidth = maxWidth.map { UIScreen.main.scale($0) }
        let scaleHeight = maxWidth.map { UIScreen.main.scale($0) }
        let validQuality = quality.map { clamp($0, min: 1, max: 100) }

        let tag = getImageTag(for: type)

        guard tag != nil || !requireTag else { return nil }

        guard let client = Container.shared.currentUserSession()?.client else { return nil }

        let parameters = Paths.GetItemImageParameters(
            maxWidth: scaleWidth,
            maxHeight: scaleHeight,
            quality: validQuality,
            tag: tag,
            format: type == .logo ? .png : nil
        )

        let request = Paths.getItemImage(
            itemID: itemID,
            imageType: type.rawValue,
            parameters: parameters
        )

        return client.fullURL(with: request)
    }

    private func getImageTag(for type: ImageType) -> String? {
        switch type {
        case .backdrop:
            backdropImageTags?.first
        case .screenshot:
            screenshotImageTags?.first
        default:
            imageTags?[type.rawValue]
        }
    }

    private func _imageSource(
        _ type: ImageType,
        maxWidth: CGFloat?,
        maxHeight: CGFloat?,
        quality: Int?
    ) -> ImageSource {
        let url = _imageURL(
            type,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            itemID: id ?? ""
        )
        let blurHash = blurHashString(for: type)

        return ImageSource(
            url: url,
            blurHash: blurHash
        )
    }
}
