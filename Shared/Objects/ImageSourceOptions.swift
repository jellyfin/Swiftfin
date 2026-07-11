//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

protocol WithImageSourceOptions {
    var maxWidth: CGFloat? { get set }
    var maxHeight: CGFloat? { get set }
    var quality: Int? { get set }
}

protocol WithParentImageSourcePreference {
    var useParent: Bool { get set }
}

struct ImageSourceOptions: WithImageSourceOptions {

    var maxWidth: CGFloat?
    var maxHeight: CGFloat?
    var quality: Int? = 90
}
