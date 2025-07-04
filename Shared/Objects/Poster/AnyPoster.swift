//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct AnyPoster: Poster {

    let _poster: any Poster

    init(_ poster: any Poster) {
        self._poster = poster
    }

    var displayTitle: String {
        _poster.displayTitle
    }

    var unwrappedIDHashOrZero: Int {
        _poster.unwrappedIDHashOrZero
    }

    var subtitle: String? {
        _poster.subtitle
    }

    var systemImage: String {
        _poster.systemImage
    }

    var id: Int {
        AnyHashable(_poster).hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(_poster.unwrappedIDHashOrZero)
        hasher.combine(_poster.displayTitle)
        hasher.combine(_poster.subtitle)
        hasher.combine(_poster.systemImage)
    }

    var showTitle: Bool {
        _poster.showTitle
    }

    func portraitImageSources(maxWidth: CGFloat?) -> [ImageSource] {
        _poster.portraitImageSources(maxWidth: maxWidth)
    }

    func landscapeImageSources(maxWidth: CGFloat?) -> [ImageSource] {
        _poster.landscapeImageSources(maxWidth: maxWidth)
    }

    func cinematicImageSources(maxWidth: CGFloat?) -> [ImageSource] {
        _poster.cinematicImageSources(maxWidth: maxWidth)
    }

    func squareImageSources(maxWidth: CGFloat?) -> [ImageSource] {
        _poster.squareImageSources(maxWidth: maxWidth)
    }

    static func == (lhs: AnyPoster, rhs: AnyPoster) -> Bool {
        lhs.id == rhs.id
    }
}
