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

class AVPlayerMediaPlayerProxy: MediaPlayerProxy {

    let avPlayerLayer: AVPlayerLayer
    private let player: AVPlayer

    init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func jumpForward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setSeconds(_ seconds: Duration) {
        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {}

    func setAudioStream(_ stream: MediaStream) {}
    func setSubtitleStream(_ stream: MediaStream) {}

    func setAspectFill(_ aspectFill: Bool) {
        avPlayerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }

    func makeVideoPlayerBody(manager: MediaPlayerManager) -> some View {
        AVPlayerView(manager: manager)
    }
}

extension AVPlayerMediaPlayerProxy {

    struct AVPlayerView: UIViewRepresentable {

        let manager: MediaPlayerManager

        func makeUIView(context: Context) -> UIView {
            let proxy = manager.proxy as! AVPlayerMediaPlayerProxy
            context.coordinator.otherDelegate.set(player: proxy.player)
            return UIAVPlayerView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {}

        func makeCoordinator() -> Coordinator {
            Coordinator(manager: manager)
        }

        class Coordinator {
            let otherDelegate: AVPlayerManagerDelegate

            init(manager: MediaPlayerManager) {
                self.otherDelegate = AVPlayerManagerDelegate(manager: manager)
            }
        }
    }

    private class UIAVPlayerView: UIView {

        let proxy: AVPlayerMediaPlayerProxy

        init(proxy: AVPlayerMediaPlayerProxy) {
            self.proxy = proxy
            super.init(frame: .zero)
            layer.addSublayer(proxy.avPlayerLayer)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            proxy.avPlayerLayer.frame = bounds
        }
    }
}
