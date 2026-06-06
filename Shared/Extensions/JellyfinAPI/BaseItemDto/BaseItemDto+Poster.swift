//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

// MARK: Poster

extension BaseItemDto: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        type?.preferredPosterDisplayType ?? .portrait
    }

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
        case .episode, .movie, .series, .video:
            "film"
        case .folder:
            "folder.fill"
        case .musicVideo:
            "music.note.tv.fill"
        case .person:
            "person.fill"
        default:
            "circle"
        }
    }

    func portraitImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            [seriesImageSource(.primary, maxWidth: maxWidth, quality: quality)]
        case .boxSet, .channel, .liveTvChannel, .movie, .musicArtist, .person, .series, .tvChannel:
            [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
        default:
            // TODO: cleanup
            // parentBackdropItemID seems good enough
            if extraType != nil, let parentBackdropItemID {
                [.init(
                    url: _imageURL(
                        .primary,
                        maxWidth: maxWidth,
                        maxHeight: nil,
                        quality: quality,
                        itemID: parentBackdropItemID,
                        requireTag: false
                    )
                )]
            } else {
                []
            }
        }
    }

    func landscapeImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            if Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop] {
                [
                    seriesImageSource(.thumb, maxWidth: maxWidth, quality: quality),
                    seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality),
                    imageSource(.primary, maxWidth: maxWidth, quality: quality),
                ]
            } else {
                [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
            }
        case .folder, .program, .musicVideo, .video:
            [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
        default:
            [
                imageSource(.thumb, maxWidth: maxWidth, quality: quality),
                imageSource(.backdrop, maxWidth: maxWidth, quality: quality),
            ]
        }
    }

    func cinematicImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        switch type {
        case .episode:
            [seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality)]
        default:
            [imageSource(.backdrop, maxWidth: maxWidth, quality: quality)]
        }
    }

    func squareImageSources(maxWidth: CGFloat?, quality: Int? = nil) -> [ImageSource] {
        switch type {
        case .audio, .channel, .musicAlbum, .tvChannel:
            [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
        default:
            []
        }
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
        switch type {
        case .channel, .tvChannel:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}
