//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import VLCUI

class VLCVideoPlayerProxy: MediaPlayerProxy {

    weak var vlcUIProxy: VLCVideoPlayer.Proxy?

    func play() {
        vlcUIProxy?.play()
    }

    func pause() {
        vlcUIProxy?.pause()
    }

    func jumpForward(_ seconds: Int) {
        vlcUIProxy?.jumpForward(seconds)
    }

    func jumpBackward(_ seconds: Int) {
        vlcUIProxy?.jumpBackward(seconds)
    }

    func setRate(_ rate: Float) {
        vlcUIProxy?.setRate(.absolute(rate))
    }

    func setTime(_ time: TimeInterval) {
        vlcUIProxy?.setTime(.seconds(time))
    }

    func stop() {
        vlcUIProxy?.stop()
    }

    func set(audioStream: MediaStream) {
        vlcUIProxy?.setAudioTrack(.absolute(audioStream.index ?? -1))
    }

    func set(subtitleStream: MediaStream) {
        vlcUIProxy?.setSubtitleTrack(.absolute(subtitleStream.index ?? -1))
    }
}
