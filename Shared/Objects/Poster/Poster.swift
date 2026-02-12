//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

// TODO: create environment for image sources
//       - for when to have episode use series
//       - pass in folder context

typealias ImageSourceBuilder = ArrayBuilder<ImageSource>

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, Identifiable, SystemImageable {

    associatedtype Environment: WithDefaultValue = Empty
    associatedtype ImageBody: View = Image
    associatedtype LabelBody: View = EmptyView
    associatedtype OverlayBody: View = EmptyView

    var preferredPosterDisplayType: PosterDisplayType { get }

    @ImageSourceBuilder
    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    @ImageSourceBuilder
    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: Environment
    ) -> [ImageSource]

    @ImageSourceBuilder
    func squareImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
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

    @MainActor
    @ViewBuilder
    var posterLabel: LabelBody { get }

    @MainActor
    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> OverlayBody
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
    func transform(image: Image, displayType: PosterDisplayType) -> ImageBody {
        image
    }
}

extension Poster where LabelBody == EmptyView {

    @MainActor
    @ViewBuilder
    var posterLabel: LabelBody {
        EmptyView()
    }
}

extension Poster where OverlayBody == EmptyView {

    @MainActor
    @ViewBuilder
    func posterOverlay(for displayType: PosterDisplayType) -> OverlayBody {
        EmptyView()
    }
}

extension Poster where Environment == Empty {

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
