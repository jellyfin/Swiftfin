//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Nuke

extension ImagePipeline {
    enum Swiftfin {}
}

extension ImagePipeline.Swiftfin {

    /// The default `ImagePipeline` to use for images that should be used
    /// during normal usage with an active connection.
    static let `default`: ImagePipeline = ImagePipeline {
        $0.dataCache = DataCache.Swiftfin.default
    }

    /// The `ImagePipeline` used for images that should have longer lifetimes and usable
    /// without a connection, like user profile images and server splashscreens.
    static let branding: ImagePipeline = ImagePipeline {
        $0.dataCache = DataCache.Swiftfin.branding
    }
}
