//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import UIKit

// MARK: PortraitPoster

extension BaseItemDto: Poster {

    var title: String {
        switch type {
        case .episode:
            return seriesName ?? displayTitle
        default:
            return displayTitle
        }
    }

    var subtitle: String? {
        switch type {
        case .episode:
            return seasonEpisodeLocator
        case .video:
            return extraType?.displayTitle
        default:
            return nil
        }
    }

    var showTitle: Bool {
        switch type {
        case .episode, .series, .movie, .boxSet, .collectionFolder:
            return Defaults[.Customization.showPosterLabels]
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

    func landscapePosterImageSources(maxWidth: CGFloat, single: Bool = false) -> [ImageSource] {
        switch type {
        case .episode:
            if single || !Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop] {
                return [imageSource(.primary, maxWidth: maxWidth)]
            } else {
                return [
                    seriesImageSource(.thumb, maxWidth: maxWidth),
                    seriesImageSource(.backdrop, maxWidth: maxWidth),
                    imageSource(.primary, maxWidth: maxWidth),
                ]
            }
        case .video:
            return [imageSource(.primary, maxWidth: maxWidth)]
        default:
            return [
                imageSource(.thumb, maxWidth: maxWidth),
                imageSource(.backdrop, maxWidth: maxWidth),
            ]
        }
    }
}
