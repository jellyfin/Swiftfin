//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI
import UIKit

extension BaseItemDto {

    /// Image source for this `BaseItemDto`
    func imageSource(
        _ type: ImageType,
        environment: some WithImageSourceOptions
    ) -> ImageSource {
        makeImageSource(
            itemID: id,
            type: type,
            blurHash: blurHash(for: type),
            environment: environment
        )
    }

    /// Image source for a specified `BaseItemDto`
    func imageSource(
        itemID: String?,
        _ type: ImageType,
        environment: some WithImageSourceOptions
    ) -> ImageSource {
        makeImageSource(
            itemID: itemID,
            type: type,
            blurHash: nil,
            environment: environment
        )
    }

    private func makeImageSource(
        itemID: String?,
        type: ImageType,
        blurHash: String?,
        environment: some WithImageSourceOptions
    ) -> ImageSource {
        ImageSource(
            url: itemID.flatMap {
                imageURL(
                    itemID: $0,
                    type,
                    environment: environment
                )
            },
            blurHash: blurHash
        )
    }

    private func blurHash(for type: ImageType) -> String? {
        guard type != .logo,
              let blurHashes = imageBlurHashes?[type] else { return nil }

        if let tag = imageTag(for: type), let taggedBlurHash = blurHashes[tag] {
            return taggedBlurHash
        }

        return blurHashes.values.first
    }

    private func imageTag(for type: ImageType) -> String? {
        switch type {
        case .backdrop:
            backdropImageTags?.first
        case .screenshot:
            screenshotImageTags?.first
        default:
            imageTags?[type.rawValue]
        }
    }

    private func imageURL(
        itemID: String? = nil,
        _ type: ImageType,
        index: Int? = nil,
        environment: some WithImageSourceOptions
    ) -> URL? {
        guard let itemID else { return nil }

        // TODO: put into environment?
        let scale = UITraitCollection.current.displayScale

        let scaleWidth = environment.maxWidth.map { Int($0 * scale) }
        let scaleHeight = environment.maxHeight.map { Int($0 * scale) }
        let validQuality = environment.quality.map { clamp($0, min: 1, max: 100) }

        guard let client = Container.shared.currentUserSession()?.client else { return nil }

        let parameters = Paths.GetItemImageParameters(
            maxWidth: scaleWidth,
            maxHeight: scaleHeight,
            quality: validQuality,
            tag: nil,
            format: type == .logo ? .png : nil,
            imageIndex: index
        )

        let request = Paths.getItemImage(
            itemID: itemID,
            imageType: type.rawValue,
            parameters: parameters
        )

        return client.url(with: request)
    }
}
