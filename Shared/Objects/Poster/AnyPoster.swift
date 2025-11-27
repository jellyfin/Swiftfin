//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct AnyPoster: Poster {

    let _poster: any Poster

    init(_ poster: any Poster) {
        self._poster = poster
    }

    var preferredPosterDisplayType: PosterDisplayType {
        _poster.preferredPosterDisplayType
    }

    var displayTitle: String {
        _poster.displayTitle
    }

    var unwrappedIDHashOrZero: Int {
        _poster.unwrappedIDHashOrZero
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
        hasher.combine(_poster.systemImage)
    }

    func landscapeImageSources(
        maxWidth: CGFloat?,
        quality: Int?,
        environment: VoidWithDefaultValue
    ) -> [ImageSource] {
        func inner(_ poster: some Poster) -> [ImageSource] {
            poster.landscapeImageSources(
                maxWidth: maxWidth,
                quality: quality,
                environment: .default
            )
        }

        return inner(_poster)
    }

    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        _poster.transform(image: image, displayType: displayType)
            .eraseToAnyView()
    }

    static func == (lhs: AnyPoster, rhs: AnyPoster) -> Bool {
        lhs.id == rhs.id
    }
}
