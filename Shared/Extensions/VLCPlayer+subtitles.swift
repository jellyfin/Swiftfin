//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import UIKit
#if os(tvOS)
    import TVVLCKit
#else
    import MobileVLCKit
#endif

extension VLCMediaPlayer {
    /// Applies font size to the player
    ///
    /// This is pretty hacky until VLCKit 4 has a public API to support this
    func setSubtitleSize(_ size: SubtitleSize) {
        perform(
            Selector(("setTextRendererFontSize:")),
            with: size.textRendererFontSize
        )
    }

    /// Applies font to the player
    ///
    /// This is pretty hacky until VLCKit 4 has a public API to support this
    func setSubtitleFont(fontName: String) {
        perform(
            Selector(("setTextRendererFont:")),
            with: fontName
        )
    }
}
