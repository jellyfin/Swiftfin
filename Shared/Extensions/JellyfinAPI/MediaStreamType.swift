//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension MediaStreamType: SupportedCaseIterable {

    // TODO: MKV can contain multiple video stream
    // - Enable .video when that multiple selection is available
    static var supportedCases: [JellyfinAPI.MediaStreamType] {
        [.audio, .subtitle] // , .video]
    }
}
