//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// A type that is displayed as a poster
protocol Poster: Displayable, Hashable, Identifiable {

    /// Optional subtitle when used as a poster
    var subtitle: String? { get }

    /// Show the title
    var showTitle: Bool { get }

    /// A system that visually represents this type
    var typeSystemImage: String? { get }

    func narrowImageSources(
        maxWidth: CGFloat?
    ) -> [ImageSource]

    func squareImageSources(
        maxWidth: CGFloat?
    ) -> [ImageSource]

    func wideImageSources(
        maxWidth: CGFloat?
    ) -> [ImageSource]
}

extension Poster {

    var subtitle: String? {
        nil
    }

    var showTitle: Bool {
        true
    }

    func narrowImageSources(
        maxWidth: CGFloat? = nil
    ) -> [ImageSource] {
        []
    }

    func squareImageSources(
        maxWidth: CGFloat? = nil
    ) -> [ImageSource] {
        []
    }

    func wideImageSources(
        maxWidth: CGFloat? = nil
    ) -> [ImageSource] {
        []
    }
}
