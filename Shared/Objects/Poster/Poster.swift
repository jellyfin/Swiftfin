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

struct VoidButWithDefaultValue: WithDefaultValue {
    let value: Void

    static var `default`: Self = .init(value: ())
}

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, LibraryIdentifiable, SystemImageable {

    associatedtype Environment: WithDefaultValue = VoidButWithDefaultValue
    associatedtype ImageBody: View = Image

    var preferredPosterDisplayType: PosterDisplayType { get }

    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    // TODO: remove and just have landscape with image size
    func cinematicImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource]

    @MainActor
    @ViewBuilder
    func transform(image: Image) -> ImageBody
}

extension Poster {

    func landscapeImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func portraitImageSources(
        maxWidth: CGFloat? = nil,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func cinematicImageSources(
        maxWidth: CGFloat?,
        quality: Int? = nil,
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource] {
        let maxWidth = size.width(for: displayType)
        let quality = size.quality

        return switch displayType {
        case .landscape:
            landscapeImageSources(
                maxWidth: maxWidth,
                quality: quality,
                environment: environment
            )
        case .portrait:
            portraitImageSources(
                maxWidth: maxWidth,
                quality: quality,
                environment: environment
            )
        case .square:
            squareImageSources(
                maxWidth: maxWidth,
                quality: quality,
                environment: environment
            )
        }
    }
}

extension Poster where ImageBody == Image {

    @MainActor
    @ViewBuilder
    func transform(image: Image) -> ImageBody {
        image
    }
}

extension Poster where Environment == VoidButWithDefaultValue {

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size
    ) -> [ImageSource] {
        imageSources(
            for: displayType,
            size: size,
            environment: .default
        )
    }
}
