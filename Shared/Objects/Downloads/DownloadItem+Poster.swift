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

extension DownloadItem: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        item.type?.preferredPosterDisplayType ?? .portrait
    }

    var subtitle: String? {
        item.subtitle
    }

    var showTitle: Bool {
        item.showTitle
    }

    func portraitImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        sources(imageURL(for: .primary))
    }

    func landscapeImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        sources(
            imageURL(for: .thumb),
            imageURL(for: .backdrop),
            imageURL(for: .primary)
        )
    }

    func cinematicImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        sources(imageURL(for: .backdrop), imageURL(for: .primary))
    }

    func squareImageSources(maxWidth: CGFloat?, quality: Int? = nil) -> [ImageSource] {
        sources(imageURL(for: .primary))
    }

    func thumbImageSources() -> [ImageSource] {
        switch preferredPosterDisplayType {
        case .portrait:
            portraitImageSources(maxWidth: 200, quality: 90)
        case .landscape:
            landscapeImageSources(maxWidth: 200, quality: 90)
        case .square:
            squareImageSources(maxWidth: 200, quality: 90)
        }
    }

    @ViewBuilder
    func transform(image: Image) -> some View {
        image.aspectRatio(contentMode: .fill)
    }

    private func sources(_ urls: URL?...) -> [ImageSource] {
        urls.compactMap(\.self).map { ImageSource(url: $0) }
    }
}
