//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

// TODO: create environment for image sources
//       - for when to have episode use series
//       - pass in folder context
//       - remove cinematic/thumb

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, LibraryIdentifiable, SystemImageable {

    associatedtype ImageBody: View

    var preferredPosterDisplayType: PosterDisplayType { get }

    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func _landscapeImageSources(
        useParent: Bool,
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func cinematicImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        useParent: Bool
    ) -> [ImageSource]

    func thumbImageSources() -> [ImageSource]

    @MainActor
    @ViewBuilder
    func transform(image: Image) -> ImageBody
}

extension Poster {

    func portraitImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil
    ) -> [ImageSource] {
        []
    }

    func landscapeImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil
    ) -> [ImageSource] {
        []
    }

    func _landscapeImageSources(
        useParent: Bool,
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource] {
        landscapeImageSources(maxWidth: maxWidth, quality: quality)
    }

    func cinematicImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil
    ) -> [ImageSource] {
        []
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil
    ) -> [ImageSource] {
        []
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        useParent: Bool
    ) -> [ImageSource] {

        let maxWidth = size.width(for: displayType)
        let quality = size.quality

        return switch displayType {
        case .portrait:
            portraitImageSources(maxWidth: maxWidth, quality: quality)
        case .landscape:
            _landscapeImageSources(
                useParent: useParent,
                maxWidth: maxWidth,
                quality: quality
            )
        case .square:
            squareImageSources(maxWidth: maxWidth, quality: quality)
        }
    }

    // TODO: change to observe preferred poster display type
    func thumbImageSources() -> [ImageSource] {
        []
    }
}
