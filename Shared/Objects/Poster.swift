//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

protocol Poster: Hashable {
    var title: String { get }
    var subtitle: String? { get }
    var showTitle: Bool { get }
}

extension Poster {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(subtitle)
    }
}

protocol PortraitPoster: Poster {
    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource
}

protocol LandscapePoster: Poster {
    func landscapePosterImageSources(maxWidth: CGFloat) -> [ImageSource]
}
