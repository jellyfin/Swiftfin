//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Foundation

class AVPlayerVideoPlayerProxy: VideoPlayerProxy {

    weak var avPlayer: AVPlayer?

    func play() {
        avPlayer?.play()
    }

    func pause() {
        avPlayer?.pause()
    }

    func jumpForward(_ seconds: Int) {
        guard let avPlayer else { return }
        let time = avPlayer.currentTime() + CMTime(value: CMTimeValue(seconds), timescale: 1)

        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Int) {
        guard let avPlayer else { return }
        let time = avPlayer.currentTime() - CMTime(value: CMTimeValue(seconds), timescale: 1)

        avPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {}

    func setTime(_ time: TimeInterval) {
        let time = CMTime(value: CMTimeValue(time), timescale: 1)
        avPlayer?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func stop() {
        avPlayer?.pause()
    }

    func play(item: VideoPlayerPlaybackItem) {}
}
