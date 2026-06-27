//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
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

    /// Home Screen Sections plugin items (Discover / Upcoming / Request) aren't real library items — their
    /// `Id` is synthetic and they carry no image tags. Instead the plugin supplies a ready-to-use poster
    /// URL inside `ProviderIds`.
    ///
    /// `ProviderIds` is a FREE-FORM `[String: String]` (Jellyfin doesn't standardize it), and the KEY a
    /// plugin uses for its poster varies by requester and version — `JellyseerrPoster` (Seerr/Overseerr
    /// Discover), `RadarrPoster` (Upcoming Movies), `SonarrPoster` (Upcoming Shows), and others on different
    /// servers. Hardcoding an exact list silently breaks on any server using a different key (the row then
    /// shows blank cards). So we resolve DYNAMICALLY, server-agnostically:
    ///   1. Prefer the well-known keys, in order, for determinism.
    ///   2. Otherwise accept ANY entry whose key looks like a poster/image and whose value is an absolute
    ///      `http(s)` URL.
    /// Real provider ids (Tmdb / Imdb / Tvdb / …) are short numeric/string ids — never URLs — so this can't
    /// match a normal library item; it only ever fires for plugin-supplied artwork.
    var pluginPosterImageSource: ImageSource? {
        guard let providerIDs, providerIDs.isNotEmpty else { return nil }

        // A plugin poster value is EITHER an absolute `http(s)` URL, OR a path RELATIVE to the Jellyfin server.
        // The HomeScreenSections *arr/Discover feature returns the latter — e.g. `/HomeScreen/CachedImage/<hash>`,
        // the plugin's OWN cached copy of the Seerr/TMDB poster, served by the Jellyfin server itself. A
        // relative path must be resolved against the CURRENT server base URL (which also preserves a subpath like
        // `/jellyfin`) — NOT against any `…Root` provider id (e.g. `JellyseerrRoot` points at the Seerr WEB APP,
        // which returns HTML, not the image). Without this the relative path was dropped and the card went blank.
        func resolveImageURL(_ value: String?) -> URL? {
            guard let value, value.isNotEmpty else { return nil }
            if let url = URL(string: value), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
                return url
            }
            // Leading slash = a server-relative path. (A real provider id like a Tmdb number never starts with
            // "/", so this can't misfire on a normal library item.)
            if value.hasPrefix("/") {
                return Container.shared.currentUserSession()?.client.url(path: value)
            }
            return nil
        }

        // 1) Preferred explicit poster keys (deterministic order).
        for key in ["JellyseerrPoster", "RadarrPoster", "SonarrPoster"] {
            if let url = resolveImageURL(providerIDs[key]) {
                return ImageSource(url: url, blurHash: nil)
            }
        }

        // 2) Fallback: any image-like key (…Poster / …Image / …Thumb / …Art) holding an http(s) URL —
        //    sorted by key so the choice is stable across launches for a given item.
        for (_, value) in providerIDs
            .filter({ key, _ in
                let k = key.lowercased()
                return k.hasSuffix("poster") || k.hasSuffix("image") || k.hasSuffix("thumb") || k.hasSuffix("art")
            })
            .sorted(by: { $0.key < $1.key })
        {
            if let url = resolveImageURL(value) {
                return ImageSource(url: url, blurHash: nil)
            }
        }

        return nil
    }

    func portraitImageSources(maxWidth: CGFloat? = nil, quality: Int? = nil) -> [ImageSource] {
        if let pluginPosterImageSource {
            return [pluginPosterImageSource]
        }

        return switch type {
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
        if let pluginPosterImageSource {
            return [pluginPosterImageSource]
        }

        return switch type {
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
        if let pluginPosterImageSource {
            return [pluginPosterImageSource]
        }

        return switch type {
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
