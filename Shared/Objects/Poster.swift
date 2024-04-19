//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: remove `showTitle` and `subtitle` since the PosterButton can define custom supplementary views?
// TODO: instead of the below image functions, have functions that match `ImageType`
//       - allows caller to choose images
protocol Poster: Displayable, Hashable, Identifiable {

    @available(*, deprecated, message: "remove this")
    var subtitle: String? { get }
    @available(*, deprecated, message: "remove this")
    var showTitle: Bool { get }
    
    var typeSystemImage: String? { get }

    @available(*, deprecated, message: "use image type functions instead")
    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource
    @available(*, deprecated, message: "use image type functions instead")
    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource]
    @available(*, deprecated, message: "use image type functions instead")
    func cinematicPosterImageSources() -> [ImageSource]
    
    
}

extension Poster {

    var showTitle: Bool {
        true
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        .init()
    }

    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool) -> [ImageSource] {
        []
    }

    func cinematicPosterImageSources() -> [ImageSource] {
        []
    }
}
