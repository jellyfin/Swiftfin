//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

protocol VideoPlayerProxy {

    func play()
    func pause()
    func stop()
    func jumpForward(_ seconds: Int)
    func jumpBackward(_ seconds: Int)
    func setSubtitleTrack(_ index: Int)
    func setAudioTrack(_ index: Int)
    func setSubtitleDelay(_ interval: TimeInterval)
    func setAudioDelay(_ interval: TimeInterval)
    func setRate(_ rate: Float)
    func setTime(_ time: TimeInterval)
}
