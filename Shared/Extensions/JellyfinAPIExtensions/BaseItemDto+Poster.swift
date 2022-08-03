//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import UIKit

// MARK: PortraitPoster

extension BaseItemDto: PortraitPoster {

    var title: String {
        switch type {
        case .episode:
            return seriesName ?? displayName
        default:
            return displayName
        }
    }

    var subtitle: String? {
        switch type {
        case .episode:
            return seasonEpisodeLocator
        default:
            return nil
        }
    }

    var showTitle: Bool {
        switch type {
        case .episode, .series, .movie, .boxSet:
            return Defaults[.showPosterLabels]
        default:
            return true
        }
    }

    func portraitPosterImageSource(maxWidth: CGFloat) -> ImageSource {
        switch type {
        case .episode:
            return seriesImageSource(.primary, maxWidth: maxWidth)
        default:
            return imageSource(.primary, maxWidth: maxWidth)
        }
    }
}

// MARK: LandscapePoster

extension BaseItemDto {
    func landscapePosterImageSources(maxWidth: CGFloat) -> [ImageSource] {
        switch type {
        case .episode:
            // TODO: Set episode image preference based on defaults
            return [
                seriesImageSource(.thumb, maxWidth: maxWidth),
                seriesImageSource(.backdrop, maxWidth: maxWidth),
                imageSource(.primary, maxWidth: maxWidth),
            ]
        default:
            return [
                imageSource(.thumb, maxWidth: maxWidth),
                imageSource(.backdrop, maxWidth: maxWidth),
            ]
        }
    }
}
