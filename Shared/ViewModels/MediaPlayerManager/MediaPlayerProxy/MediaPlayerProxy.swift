//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// The proxy for top-down communication to an
/// underlying media player
protocol MediaPlayerProxy {

    func play()
    func pause()
    func jumpForward(_ seconds: TimeInterval)
    func jumpBackward(_ seconds: TimeInterval)
    func setRate(_ rate: Float)
    func setTime(_ time: TimeInterval)
    func setAudioStream(_ stream: MediaStream)
    func setSubtitleStream(_ stream: MediaStream)

    func stop()
}
