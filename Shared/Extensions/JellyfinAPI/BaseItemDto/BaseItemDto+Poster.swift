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

private let landscapeWidth: CGFloat = 110
private let portraitWidth: CGFloat = 60

extension BaseItemDto: Poster {

    struct Environment: WithDefaultValue, WithViewContext {
        let useParent: Bool
        var viewContext: ViewContext

        init(
            useParent: Bool = false,
            viewContext: ViewContext = .init()
        ) {
            self.useParent = useParent
            self.viewContext = viewContext
        }

        static let `default`: Self = .init()
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
        case .boxSet, .channel, .liveTvChannel, .movie, .musicArtist, .series, .tvChannel:
            imageSource(
                .primary,
                maxWidth: maxWidth,
                quality: quality
            )
        case .person:
            imageSource(
                .primary,
                maxWidth: maxWidth,
                quality: quality,
                requireTag: false
            )
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
                if environment.viewContext.contains(.isThumb) {
                    seriesImageSource(.thumb, maxWidth: maxWidth, quality: quality)
                }
                seriesImageSource(.backdrop, maxWidth: maxWidth, quality: quality)
                imageSource(.primary, maxWidth: maxWidth, quality: quality)
            } else {
                imageSource(.primary, maxWidth: maxWidth, quality: quality)
            }
        case .collectionFolder, .folder, .musicVideo, .liveTvProgram, .program, .userView, .video:
            imageSource(.primary, maxWidth: maxWidth, quality: quality)
        default:
            if environment.viewContext.contains(.isThumb) {
                imageSource(.thumb, maxWidth: maxWidth, quality: quality)
            }
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

    @ViewBuilder
    var posterLabel: some View {
        _BaseItemPosterLabel(item: self)
    }

    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        WithEnvironment(\.viewContext) { viewContext in
            if viewContext.contains(.isInResume) {
                PosterIndicatorsOverlay(
                    item: self,
                    indicators: .progress,
                    posterDisplayType: displayType
                )
            } else {
                WithDefaults(.Customization.Indicators.enabled) { indicators in
                    PosterIndicatorsOverlay(
                        item: self,
                        indicators: indicators,
                        posterDisplayType: displayType
                    )
                }
            }
        }
    }
}

private struct _BaseItemPosterLabel: View {

    @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
    private var useSeriesLandscapeBackdrop

    let item: BaseItemDto

    var body: some View {
        switch item.type {
        case .liveTvProgram, .program, .tvProgram:
            VStack(alignment: .leading) {

                Text(item.channelName ?? .emptyDash)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(item.displayTitle)
                    .font(.callout)
                    .lineLimit(1)

                SeparatorHStack {
                    Text("-")
                } content: {
                    if let startDate = item.startDate {
                        Text(startDate, style: .time)
                    } else {
                        Text(String.emptyDash)
                    }

                    if let endDate = item.endDate {
                        Text(endDate, style: .time)
                    } else {
                        Text(String.emptyDash)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        case .episode:
            TitleSubtitleContentView(
                title: item.seriesName ?? L10n.unknown
            ) {
                AlternateLayoutView(alignment: .leading) {
                    Text(" ")
                        .frame(maxWidth: .infinity)
                } content: {
                    DotHStack(padding: 2) {
                        if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                            Text(seasonEpisodeLabel)
                        }
                    }
                }
            }
        default:
            TitleSubtitleContentView(
                title: item.displayTitle
            ) {
                AlternateLayoutView(alignment: .leading) {
                    Text(" ")
                        .frame(maxWidth: .infinity)
                } content: {
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                    }
                }
            }
        }
    }
}

extension BaseItemDto: LibraryElement {

    @MainActor
    func libraryDidSelectElement(router: Router.Wrapper, in namespace: Namespace.ID) {
        switch type {
        case .collectionFolder, .folder, .userView:
            let library = ItemLibrary(parent: self)
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
