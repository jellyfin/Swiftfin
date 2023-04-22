//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation

protocol Poster: Displayable, Hashable {

    var subtitle: String? { get }
    var showTitle: Bool { get }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource
    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource]
}

extension Poster {
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayTitle)
        hasher.combine(subtitle)
    }
}
