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

extension DownloadEntry: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        item.preferredPosterDisplayType
    }

    var subtitle: String? {
        item.subtitle
    }

    var showTitle: Bool {
        item.showTitle
    }

    func portraitImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        completed?.portraitImageSources(maxWidth: maxWidth, quality: quality) ?? []
    }

    func landscapeImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        completed?.landscapeImageSources(maxWidth: maxWidth, quality: quality) ?? []
    }

    func cinematicImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        completed?.cinematicImageSources(maxWidth: maxWidth, quality: quality) ?? []
    }

    func squareImageSources(maxWidth: CGFloat?, quality: Int? = nil) -> [ImageSource] {
        completed?.squareImageSources(maxWidth: maxWidth, quality: quality) ?? []
    }

    func thumbImageSources() -> [ImageSource] {
        completed?.thumbImageSources() ?? []
    }

    @ViewBuilder
    func transform(image: Image) -> some View {
        item.transform(image: image)
    }
}
