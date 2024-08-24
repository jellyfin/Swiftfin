//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// Currently, only reflects commands that happen
// through implements NowPlayableCommands
protocol VideoPlayerProxy {

    func play()
    func pause()
    func jumpForward(_ seconds: Int)
    func jumpBackward(_ seconds: Int)
    func setRate(_ rate: Float)
    func setTime(_ time: TimeInterval)

    func play(item: VideoPlayerItem)
}
