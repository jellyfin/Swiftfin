//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging
import VLCUI

extension MediaStreamType: SupportedCaseIterable {

    /// Cases supported for track switching
    static var supportedCases: [MediaStreamType] {
        [.audio, .subtitle]
    }
}
