//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

typealias ImageSourceBuilder = ArrayBuilder<ImageSource>

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, Identifiable, SystemImageable {

    associatedtype Environment: WithDefaultValue = Empty
    associatedtype ImageBody: View = Image

    var preferredPosterDisplayType: PosterDisplayType { get }

    /// Optional subtitle when used as a poster
    var subtitle: String? { get }

    /// Show the title
    var showTitle: Bool { get }

    @ImageSourceBuilder
    func portraitImageSources(
        environment: Environment
    ) -> [ImageSource]

    @ImageSourceBuilder
    func landscapeImageSources(
        environment: Environment
    ) -> [ImageSource]

    @ImageSourceBuilder
    func squareImageSources(
        environment: Environment
    ) -> [ImageSource]

    @ImageSourceBuilder
    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource]

    @MainActor
    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> ImageBody
}

extension Poster where ImageBody == Image {

    @MainActor
    func transform(image: Image) -> Image {
        image
    }

    @MainActor
    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> ImageBody {
        image
    }
}

extension Poster {

    var subtitle: String? {
        nil
    }

    var showTitle: Bool {
        true
    }

    func portraitImageSources(
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func landscapeImageSources(
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func squareImageSources(
        environment: Environment
    ) -> [ImageSource] {
        []
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource] {
        var environment = environment

        if var imageSourceEnvironment = environment as? WithImageSourceOptions {
            imageSourceEnvironment.maxWidth = size.width(for: displayType)
            imageSourceEnvironment.quality = size.quality
            environment = imageSourceEnvironment as! Environment
        }

        return switch displayType {
        case .landscape:
            landscapeImageSources(
                environment: environment
            )
        case .portrait:
            portraitImageSources(
                environment: environment
            )
        case .square:
            squareImageSources(
                environment: environment
            )
        }
    }

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

    func _withLandscapeImages(_ imageSources: @escaping (AnyPoster.Environment) -> [ImageSource]) -> AnyPoster {
        .init(self, _withLandscapeImages: imageSources)
    }
}
