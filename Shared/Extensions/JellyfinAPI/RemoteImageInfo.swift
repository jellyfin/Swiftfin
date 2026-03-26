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

extension RemoteImageInfo: @retroactive Identifiable {

    public var id: Int {
        hashValue
    }

    var primaryImageSource: ImageSource {
        ImageSource(url: url?.url)
    }

    var thumbnailImageSource: ImageSource {
        ImageSource(url: thumbnailURL?.url)
    }

    private var imageSources: [ImageSource] {
        [thumbnailImageSource, primaryImageSource]
    }
}

extension RemoteImageInfo: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        type?.posterDisplayType() ?? .landscape
    }

    var displayTitle: String {
        providerName ?? L10n.unknown
    }

    var unwrappedIDHashOrZero: Int {
        id
    }

    var subtitle: String? {
        language
    }

    var systemImage: String {
        "photo"
    }

    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        imageSources
    }

    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        imageSources
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        imageSources
    }
}
