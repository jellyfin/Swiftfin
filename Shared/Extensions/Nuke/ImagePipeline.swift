//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Nuke

extension ImagePipeline {

    enum Swiftfin {}

    static func cacheKey(for url: URL) -> String? {
        guard var components = url.components else { return nil }

        var maxWidthValue: String?

        if let maxWidth = components.queryItems?.first(where: { $0.name == "maxWidth" }) {
            maxWidthValue = maxWidth.value
            components.queryItems = components.queryItems?.filter { $0.name != "maxWidth" }
        }

        guard let newURL = components.url, let urlSHA = newURL.pathAndQuery?.sha1 else { return nil }

        if let maxWidthValue {
            return urlSHA + "-\(maxWidthValue)"
        } else {
            return urlSHA
        }
    }

    func removeItem(for url: URL) {
        let request = ImageRequest(url: url)
        cache.removeCachedImage(for: request)
        cache.removeCachedData(for: request)

        guard let dataCacheKey = Self.cacheKey(for: url) else { return }
        configuration.dataCache?.removeData(for: dataCacheKey)
    }
}

extension ImagePipeline.Swiftfin {

    /// The default `ImagePipeline` to use for images that are typically posters
    /// or server user images that should be presentable with an active connection.
    static let posters: ImagePipeline = ImagePipeline(delegate: SwiftfinImagePipelineDelegate()) {
        $0.dataCache = DataCache.Swiftfin.posters
    }

    /// The `ImagePipeline` used for images that should have longer lifetimes and usable
    /// without a connection, likes local user profile images and server splashscreens.
    static let local: ImagePipeline = ImagePipeline(delegate: SwiftfinImagePipelineDelegate()) {
        $0.dataCache = DataCache.Swiftfin.local
    }

    /// An `ImagePipeline` for images to prevent more important images from losing their cache.
    static let other: ImagePipeline = ImagePipeline(configuration: .withURLCache)
}

final class SwiftfinImagePipelineDelegate: ImagePipelineDelegate {

    func cacheKey(for request: ImageRequest, pipeline: ImagePipeline) -> String? {
        guard let url = request.url else { return nil }
        return ImagePipeline.cacheKey(for: url)
    }
}
