//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import UIKit

// MARK: PortraitPoster

extension BaseItemDto: Poster {

    var subtitle: String? {
        switch type {
        case .episode:
            seasonEpisodeLabel
        case .video:
            extraType?.displayTitle
        default:
            nil
        }
    }

    var showTitle: Bool {
        switch type {
        case .episode, .series, .movie, .boxSet, .collectionFolder:
            Defaults[.Customization.showPosterLabels]
        default:
            true
        }
    }

    var systemImage: String {
        switch type {
        case .audio, .musicAlbum:
            "music.note"
        case .boxSet:
            "film.stack"
        case .channel, .tvChannel, .liveTvChannel, .program:
            "tv"
        case .episode, .movie, .series:
            "film"
        case .folder:
            "folder.fill"
        case .person:
            "person.fill"
        default:
            "circle"
        }
    }

    func portraitImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            [seriesImageSource(.primary, maxWidth: maxWidth)]
        case .boxSet, .channel, .tvChannel, .liveTvChannel, .movie, .series:
            [imageSource(.primary, maxWidth: maxWidth)]
        default:
            []
        }
    }

    func landscapeImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            if Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop] {
                [
                    seriesImageSource(.thumb, maxWidth: maxWidth),
                    seriesImageSource(.backdrop, maxWidth: maxWidth),
                    imageSource(.primary, maxWidth: maxWidth),
                ]
            } else {
                [imageSource(.primary, maxWidth: maxWidth)]
            }
        case .folder, .program, .video:
            [imageSource(.primary, maxWidth: maxWidth)]
        default:
            [
                imageSource(.thumb, maxWidth: maxWidth),
                imageSource(.backdrop, maxWidth: maxWidth),
            ]
        }
    }

    func cinematicImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            [seriesImageSource(.backdrop, maxWidth: maxWidth)]
        default:
            [imageSource(.backdrop, maxWidth: maxWidth)]
        }
    }

    func squareImageSources(maxWidth: CGFloat?) -> [ImageSource] {
        switch type {
        case .audio, .musicAlbum:
            [imageSource(.primary, maxWidth: maxWidth)]
        default:
            []
        }
    }
}
