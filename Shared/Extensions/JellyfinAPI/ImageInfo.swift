//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension ImageInfo: @retroactive Identifiable {

    public var id: Int {
        hashValue
    }
}

extension ImageInfo: Poster {

    struct Environment: WithDefaultValue {
        let itemID: String
        let client: JellyfinClient

        static let `default` = Environment(
            itemID: "",
            client: .init(
                configuration: .init(
                    url: URL(string: "/")!,
                    client: "unknown",
                    deviceName: "unknown",
                    deviceID: "unknown",
                    version: "unknown"
                )
            )
        )

        static func == (lhs: Environment, rhs: Environment) -> Bool {
            lhs.itemID == rhs.itemID && lhs.client === rhs.client
        }
    }

    var preferredPosterDisplayType: PosterDisplayType {
        guard let height, let width else {
            return .square
        }

        if height == width {
            return .square
        }

        return width > height ? .landscape : .portrait
    }

    var displayTitle: String {
        imageType?.displayTitle ?? L10n.unknown
    }

    var unwrappedIDHashOrZero: Int {
        id
    }

    var systemImage: String {
        "photo"
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource] {
        guard let imageSource = itemImageSource(
            itemID: environment.itemID,
            client: environment.client
        ) else {
            return []
        }

        return [imageSource]
    }

    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        switch imageType {
        case .logo:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}

extension ImageInfo {

    func itemImageSource(itemID: String, client: JellyfinClient) -> ImageSource? {
        guard let imageType else {
            return nil
        }

        let parameters = Paths.GetItemImageParameters(
            tag: imageTag,
            imageIndex: imageIndex
        )
        let request = Paths.getItemImage(
            itemID: itemID,
            imageType: imageType.rawValue,
            parameters: parameters
        )

        let itemImageURL = client.fullURL(with: request)

        return ImageSource(url: itemImageURL)
    }
}
