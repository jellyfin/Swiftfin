//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum VideoPlayerGesture {
    
    enum MultiTap {
        
    }
    
    enum Pan {
        // Pan
        case audioOffset
        case brightness
        case playbackSpeed
        case scrub
        case slowScrub
        case subtitleOffset
        case volume
    }
    
    enum Swipe {
        case jump
    }
}

enum VideoPlayerHorizontalGesture: String, CaseIterable, Defaults.Serializable, Displayable {
    // Pan
    case panScrub
    case panSlowScrub
    
    // Swipe
    case swipeJump
    
    var displayTitle: String {
        switch self {
        case .panScrub:
            return "Scrub"
        case .panSlowScrub:
            return "Slow Scrub"
        case .swipeJump:
            return "Jump"
        }
    }
}
