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

extension DownloadTask: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        item.preferredPosterDisplayType
    }

    var subtitle: String? {
        item.subtitle
    }

    @ViewBuilder
    var posterLabel: some View {
        item.posterLabel
    }

    func portraitImageSources(environment: Empty) -> [ImageSource] {
        localSources(item.portraitImageSources(environment: .default))
    }

    func landscapeImageSources(environment: Empty) -> [ImageSource] {
        localSources(item.landscapeImageSources(environment: .default))
    }

    func squareImageSources(environment: Empty) -> [ImageSource] {
        localSources(item.squareImageSources(environment: .default))
    }

    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        item.transform(image: image, displayType: displayType)
    }

    private func localSources(_ sources: [ImageSource]) -> [ImageSource] {
        guard isCompleted else { return [] }
        return sources.compactMap { source in
            guard let url = source.url, let local = localFileURL(for: url) else { return nil }
            return ImageSource(url: local, blurHash: source.blurHash)
        }
    }
}
