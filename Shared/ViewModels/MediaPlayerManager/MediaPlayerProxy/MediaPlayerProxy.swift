//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

/// The proxy for top-down communication to an
/// underlying media player
protocol MediaPlayerProxy {

    func play()
    func pause()
    func jumpForward(_ seconds: Int)
    func jumpBackward(_ seconds: Int)
    func setRate(_ rate: Float)
    func setTime(_ time: TimeInterval)

    func stop()

    func play(item: MediaPlayerItem)
}
