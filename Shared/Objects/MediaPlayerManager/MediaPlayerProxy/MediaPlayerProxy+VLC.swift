//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    func jumpForward(_ seconds: Duration) {
        vlcUIProxy?.jumpForward(Int(seconds.components.seconds))
    }

    func jumpBackward(_ seconds: Duration) {
        vlcUIProxy?.jumpBackward(Int(seconds.components.seconds))
    }

    func setRate(_ rate: Float) {
        vlcUIProxy?.setRate(.absolute(rate))
    }

    func setSeconds(_ seconds: Duration) {
        vlcUIProxy?.setSeconds(seconds)
    }

    func stop() {
        vlcUIProxy?.stop()
    }

    func setAudioStream(_ stream: MediaStream) {
        vlcUIProxy?.setAudioTrack(.absolute(stream.index ?? -1))
    }

    func setSubtitleStream(_ stream: MediaStream) {
        vlcUIProxy?.setSubtitleTrack(.absolute(stream.index ?? -1))
    }
}
