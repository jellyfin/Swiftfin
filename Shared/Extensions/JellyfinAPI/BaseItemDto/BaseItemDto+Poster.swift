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
import SwiftUI

// MARK: Poster

extension BaseItemDto: Poster {

    struct Environment: CustomEnvironmentValue {
        let useParent: Bool

        static let `default` = Environment(useParent: false)
    }

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
        case .collectionFolder, .folder, .userView:
            "folder.fill"
        case .musicVideo:
            "music.note.tv.fill"
        case .person:
            "person.fill"
        default:
            "circle"
        }
    }

    func portraitImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
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

    func landscapeImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .episode:
            if environment.useParent {
                [
                    seriesImageSource(.thumb, maxWidth: maxWidth, quality: quality),
                    seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality),
                    imageSource(.primary, maxWidth: maxWidth, quality: quality),
                ]
            } else {
                [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
            }
        case .collectionFolder, .folder, .musicVideo, .program, .userView, .video:
            [imageSource(.primary, maxWidth: maxWidth, quality: quality)]
        default:
            [
                imageSource(.thumb, maxWidth: maxWidth, quality: quality),
                imageSource(.backdrop, maxWidth: maxWidth, quality: quality),
            ]
        }
    }

    func cinematicImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .episode:
            [seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality)]
        default:
            [imageSource(.backdrop, maxWidth: maxWidth, quality: quality)]
        }
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .audio, .channel, .musicAlbum, .tvChannel:
            [
                // TODO: generalize blurhash retrieval
                imageSource(.primary, maxWidth: maxWidth, quality: quality),
                imageSource(
                    id: albumID,
                    blurHash: imageBlurHashes?.primary?.first?.value,
                    .primary,
                    maxWidth: maxWidth,
                    quality: quality
                ),
            ]
        default:
            []
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

extension BaseItemDto: LibraryElement {

    func librarySelectAction(router: Router.Wrapper, in namespace: Namespace) {}

    func makeBody(libraryStyle: LibraryStyle) -> some View {
        Color.red
            .frame(height: 50)
    }
}
