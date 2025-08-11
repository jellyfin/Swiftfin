//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: make AVPlayerLayer backed video view

class AVPlayerMediaPlayerProxy: MediaPlayerProxy {

    weak var avPlayer: AVPlayer?

    func play() {
        avPlayer?.play()
    }

    func pause() {
        avPlayer?.pause()
    }

    func jumpForward(_ seconds: Duration) {
        guard let avPlayer else { return }
        let currentTime = avPlayer.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        guard let avPlayer else { return }
        let currentTime = avPlayer.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))
        avPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setSeconds(_ seconds: Duration) {
        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        avPlayer?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {}

    func setAspectFill(_ aspectFill: Bool) {}

    func stop() {
        avPlayer?.pause()
    }

    func setAudioStream(_ stream: MediaStream) {}
    func setSubtitleStream(_ stream: MediaStream) {}

    func makeVideoPlayerBody(manager: MediaPlayerManager) -> some View {
        NativeVideoPlayer(manager: manager)
    }
}
