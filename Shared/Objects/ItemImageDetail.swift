//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Shared components for remote and local item ImageInfo
protocol ItemImageDetail {

    var index: Int? { get }
    var width: Int? { get }
    var height: Int? { get }
    var language: String? { get }
    var provider: String? { get }
    var rating: Double? { get }
    var ratingVotes: Int? { get }

    func imageSource(item: BaseItemDto?) -> ImageSource
}
