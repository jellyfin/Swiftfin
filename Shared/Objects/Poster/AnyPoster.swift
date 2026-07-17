//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

private func anyPosterPortraitImageSources(
    for poster: some Poster
) -> [ImageSource] {
    poster.portraitImageSources(environment: .default)
}

private func anyPosterLandscapeImageSources(
    for poster: some Poster
) -> [ImageSource] {
    poster.landscapeImageSources(environment: .default)
}

private func anyPosterSquareImageSources(
    for poster: some Poster
) -> [ImageSource] {
    poster.squareImageSources(environment: .default)
}

private func anyPosterImageSources(
    for poster: some Poster,
    displayType: PosterDisplayType,
    size: PosterDisplayType.Size
) -> [ImageSource] {
    poster.imageSources(for: displayType, size: size)
}

struct AnyPoster: Poster {

    struct ID: Hashable {
        let posterType: ObjectIdentifier
        let value: AnyHashable
    }

    struct Environment: WithDefaultValue, WithImageSourceOptions {

        var maxWidth: CGFloat?
        var maxHeight: CGFloat?
        var quality: Int?

        static var `default`: Self {
            .init()
        }
    }

    let _poster: any Poster

    private let _id: ID
    private let _withLandscapeImages: ((Environment) -> [ImageSource])?

    init<P: Poster>(
        _ poster: P,
        _withLandscapeImages: ((Environment) -> [ImageSource])? = nil
    ) {
        self._poster = poster
        self._id = ID(
            posterType: ObjectIdentifier(P.self),
            value: AnyHashable(poster.id)
        )
        self._withLandscapeImages = _withLandscapeImages
    }

    var preferredPosterDisplayType: PosterDisplayType {
        _poster.preferredPosterDisplayType
    }

    var displayTitle: String {
        _poster.displayTitle
    }

    var subtitle: String? {
        _poster.subtitle
    }

    var systemImage: String {
        _poster.systemImage
    }

    var id: ID {
        _id
    }

    var posterLabel: some View {
        _poster.posterLabel
            .eraseToAnyView()
    }

    var posterContextMenu: some View {
        _poster.posterContextMenu
            .eraseToAnyView()
    }

    func posterOverlay(for displayType: PosterDisplayType) -> some View {
        _poster.posterOverlay(for: displayType)
            .eraseToAnyView()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func portraitImageSources(
        environment: Environment
    ) -> [ImageSource] {
        anyPosterPortraitImageSources(for: _poster)
    }

    func landscapeImageSources(
        environment: Environment
    ) -> [ImageSource] {
        if let _withLandscapeImages {
            _withLandscapeImages(environment)
        } else {
            anyPosterLandscapeImageSources(for: _poster)
        }
    }

    func squareImageSources(
        environment: Environment
    ) -> [ImageSource] {
        anyPosterSquareImageSources(for: _poster)
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> [ImageSource] {
        if displayType == .landscape, let _withLandscapeImages {
            _withLandscapeImages(
                imageSourceEnvironment(
                    for: displayType,
                    size: size,
                    environment: environment
                )
            )
        } else {
            anyPosterImageSources(
                for: _poster,
                displayType: displayType,
                size: size
            )
        }
    }

    private func imageSourceEnvironment(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: Environment
    ) -> Environment {
        var environment = environment
        environment.maxWidth = size.width(for: displayType)
        environment.quality = size.quality

        return environment
    }

    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        _poster.transform(image: image, displayType: displayType)
            .eraseToAnyView()
    }

    static func == (lhs: AnyPoster, rhs: AnyPoster) -> Bool {
        lhs.id == rhs.id
    }
}
