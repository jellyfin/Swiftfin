//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

enum VideoPlayerType: String, CaseIterable, Defaults.Serializable, Displayable {

    case native
    case swiftfin

    var displayTitle: String {
        switch self {
        case .native:
            "Native"
        case .swiftfin:
            "Swiftfin"
        }
    }

    var directPlayProfiles: [DirectPlayProfile] {
        switch self {
        case .native:
            Self._nativeDirectPlayProfiles
        case .swiftfin:
            Self._swiftfinDirectPlayProfiles
        }
    }

    var transcodingProfiles: [TranscodingProfile] {
        switch self {
        case .native:
            Self._nativeTranscodingProfiles
        case .swiftfin:
            Self._swiftfinTranscodingProfiles
        }
    }

    var subtitleProfiles: [SubtitleProfile] {
        switch self {
        case .native:
            Self._nativeSubtitleProfiles
        case .swiftfin:
            Self._swiftfinSubtitleProfiles
        }
    }
}
