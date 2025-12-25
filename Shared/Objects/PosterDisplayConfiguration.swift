//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

struct PosterDisplayConfiguration: Equatable, WithDefaultValue, Storable {

    var displayType: PosterDisplayType
    var size: PosterDisplayType.Size

    enum CodingKeys: String, CodingKey {
        case displayType
        case size
    }

    static let `default`: PosterDisplayConfiguration = .init(
        displayType: .portrait,
        size: .small
    )
}
