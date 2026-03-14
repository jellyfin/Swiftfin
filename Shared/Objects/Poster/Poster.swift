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
//       - thumb
//       - could remove cinematic, just use landscape

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, LibraryIdentifiable, SystemImageable {

    associatedtype ImageBody: View

    var preferredPosterDisplayType: PosterDisplayType { get }

    /// Optional subtitle when used as a poster
    var subtitle: String? { get }

    /// Show the title
    var showTitle: Bool { get }

    func portraitImageSources(
        maxWidth: CGFloat?,
        quality: Int?
    ) -> [ImageSource]

    func landscapeImageSources(
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

    func thumbImageSources() -> [ImageSource]

    @MainActor
    @ViewBuilder
    func transform(image: Image) -> ImageBody
}

extension Poster {

    var subtitle: String? {
        nil
    }

    var showTitle: Bool {
        true
    }

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

    // TODO: change to observe preferred poster display type
    func thumbImageSources() -> [ImageSource] {
        []
    }
}
