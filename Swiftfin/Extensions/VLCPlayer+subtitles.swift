//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import MobileVLCKit

extension VLCMediaPlayer {
    /// Applies font size to the player
    ///
    /// This is pretty hacky until VLCKit 4 has a public API to support this
    /// Supposedly it also does not work for tvOS
    func setSubtitleSize(_ size: SubtitleSize) {
        perform(
            Selector(("setTextRendererFontSize:")),
            with: size.textRendererFontSize
        )
    }
}
