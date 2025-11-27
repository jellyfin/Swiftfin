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
            seriesImageSource(.primary, maxWidth: maxWidth, quality: quality)
        case .boxSet, .channel, .liveTvChannel, .movie, .musicArtist, .person, .series, .tvChannel:
            imageSource(.primary, maxWidth: maxWidth, quality: quality)
        default:
            // TODO: cleanup
            // parentBackdropItemID seems good enough
            if extraType != nil, let parentBackdropItemID {
                .init(
                    url: _imageURL(
                        .primary,
                        maxWidth: maxWidth,
                        maxHeight: nil,
                        quality: quality,
                        itemID: parentBackdropItemID,
                        requireTag: false
                    )
                )
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
                seriesImageSource(.thumb, maxWidth: maxWidth, quality: quality)
                seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality)
                imageSource(.primary, maxWidth: maxWidth, quality: quality)
            } else {
                imageSource(.primary, maxWidth: maxWidth, quality: quality)
            }
        case .collectionFolder, .folder, .musicVideo, .program, .userView, .video:
            imageSource(.primary, maxWidth: maxWidth, quality: quality)
        default:
            imageSource(.thumb, maxWidth: maxWidth, quality: quality)
            imageSource(.backdrop, maxWidth: maxWidth, quality: quality)
        }
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        switch type {
        case .audio, .channel, .musicAlbum, .tvChannel:
            // TODO: generalize blurhash retrieval
            imageSource(.primary, maxWidth: maxWidth, quality: quality)
            imageSource(
                id: albumID,
                blurHash: imageBlurHashes?.primary?.first?.value,
                .primary,
                maxWidth: maxWidth,
                quality: quality
            )
        case .program:
            if let channelID {
                imageSource(
                    id: channelID,
                    .primary,
                    maxWidth: maxWidth,
                    quality: quality
                )
            }
        default:
            []
        }
    }

    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        switch type {
        case .channel, .tvChannel:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        case .program:
            if displayType == .square {
                // Using channel from above
                ContainerRelativeView(ratio: 0.95) {
                    image
                        .aspectRatio(contentMode: .fit)
                }
            } else {
                image
                    .aspectRatio(contentMode: .fill)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}

private let landscapeWidth: CGFloat = 110
private let portraitWidth: CGFloat = 60

extension BaseItemDto: LibraryElement {

    @MainActor
    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        switch type {
        case .collectionFolder, .folder, .userView:
            let library = PagingItemLibrary(parent: self)
            router.route(to: .library(library: library), in: namespace)
        default:
            router.route(to: .item(item: self), in: namespace)
        }
    }

    func makeGridBody(libraryStyle: LibraryStyle) -> some View {
        WithRouter { router in
            PosterButton(
                item: self,
                type: libraryStyle.posterDisplayType
            ) { namespace in
                libraryDidSelectElement(router: router, in: namespace)
            } label: {
                EmptyView()
            }
        }
    }

    func makeListBody(libraryStyle: LibraryStyle) -> some View {
        WithNamespace { namespace in
            WithRouter { router in
                ListRow(insets: .init(vertical: 8, horizontal: EdgeInsets.edgePadding)) {
                    libraryDidSelectElement(router: router, in: namespace)
                } leading: {
                    PosterImage(
                        item: self,
                        type: libraryStyle.posterDisplayType,
                        contentMode: .fill
                    )
                    .posterShadow()
                    .frame(width: libraryStyle.posterDisplayType == .landscape ? landscapeWidth : portraitWidth)
                } content: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(displayTitle)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        accessoryView
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .backport
                .matchedTransitionSource(id: "item", in: namespace)
            }
        }
    }

    @ViewBuilder
    private var accessoryView: some View {
        DotHStack {
            if type == .episode, let seasonEpisodeLocator = seasonEpisodeLabel {
                Text(seasonEpisodeLocator)
            } else if let premiereYear = premiereDateYear {
                Text(premiereYear)
            }

            if let runtime {
                Text(runtime, format: .runtime)
            }

            if let officialRating {
                Text(officialRating)
            }
        }
    }
}
