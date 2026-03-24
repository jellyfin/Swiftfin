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

extension RemoteImageInfo: @retroactive Identifiable, ItemImageDetail {

    var index: Int? {
        nil
    }

    var provider: String? {
        providerName
    }

    var rating: Double? {
        communityRating
    }

    var ratingVotes: Int? {
        voteCount
    }

    func imageSource(item: BaseItemDto? = nil) -> ImageSource {
        ImageSource(url: url?.url)
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
        [ImageSource(url: thumbnailURL?.url), ImageSource(url: url?.url)]
    }

    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        [ImageSource(url: thumbnailURL?.url), ImageSource(url: url?.url)]
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        [ImageSource(url: thumbnailURL?.url), ImageSource(url: url?.url)]
    }

    public var id: Int {
        hashValue
    }

    func transform(image: Image) -> some View {
        image
    }
}
