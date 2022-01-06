//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation

protocol PlayerOverlayDelegate {
    
    func didSelectClose()
    func didSelectMenu()
    
    func didSelectBackward()
    func didSelectForward()
    func didSelectMain()
    
    func didGenerallyTap()
    
    func didBeginScrubbing()
    func didEndScrubbing()
    
    func didSelectAudioStream(index: Int)
    func didSelectSubtitleStream(index: Int)
    
    func didSelectPlayPreviousItem()
    func didSelectPlayNextItem()
}
