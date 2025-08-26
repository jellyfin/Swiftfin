//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: After NativeVideoPlayer is removed, can move bindings and
//       observers to AVPlayerView, like the VLC delegate
//       - wouldn't need to have MediaPlayerProxy: MediaPlayerObserver
// TODO: report playback information, see VLCUI.PlaybackInformation (dropped frames, etc.)
// TODO: manager able to replace MediaPlayerItem in-place for changing audio/subtitle tracks
// TODO: report buffering state

class AVMediaPlayerProxy: MediaPlayerProxy {

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSKeyValueObservation!
    private var timeObserver: Any!
    private var managerItemObserver: AnyCancellable?
    private var managerStateObserver: AnyCancellable?

    weak var manager: MediaPlayerManager? {
        didSet {
            if let manager {
                managerItemObserver = manager.$playbackItem
                    .sink { playbackItem in
                        if let playbackItem {
                            self.playNew(playbackItem: playbackItem)
                        }
                    }

                managerStateObserver = manager.$state
                    .sink { state in
                        switch state {
                        case .stopped:
                            self.playbackStopped()
                        default: break
                        }
                    }
            } else {
                managerItemObserver?.cancel()
                managerStateObserver?.cancel()
            }
        }
    }

    init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)

        print("AVPlayerMediaPlayerProxy initialized")

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { newTime in
            let newSeconds = Duration.seconds(newTime.seconds)

            if !self.isScrubbing.wrappedValue {
                self.scrubbedSeconds.wrappedValue = newSeconds
            }

            self.manager?.seconds = newSeconds
        }

        if let playbackItem = manager?.playbackItem {
            playNew(playbackItem: playbackItem)
        }
    }

    deinit {
        print("AVPlayerMediaPlayerProxy deinitialized")
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

    func makeVideoPlayerBody() -> some View {
        AVPlayerView(proxy: self)
    }
}

extension AVMediaPlayerProxy {

    private func playbackStopped() {
        player.pause()
        guard let timeObserver else { return }
        player.removeTimeObserver(timeObserver)
        rateObserver.invalidate()
        statusObserver.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func playNew(playbackItem: MediaPlayerItem) {
        let newAVPlayerItem = AVPlayerItem(url: playbackItem.url)
        newAVPlayerItem.externalMetadata = playbackItem.baseItem.avMetadata

        player.replaceCurrentItem(with: newAVPlayerItem)

        rateObserver = player.observe(\.rate, options: [.new, .initial]) { _, value in
            DispatchQueue.main.async {
                self.manager?.set(rate: value.newValue ?? 1.0)
            }
        }

        statusObserver = player.observe(\.currentItem?.status, options: [.new, .initial]) { _, value in
            guard let newValue = value.newValue else { return }
            switch newValue {
            case .failed:
                if let error = self.player.error {
                    DispatchQueue.main.async {
                        self.manager?.send(.error(.init("AVPlayer error: \(error.localizedDescription)")))
                    }
                }
            case .readyToPlay:
                self.player.play()
            case .none, .unknown:
                print("here")
                self.player.play()
            @unknown default: ()
            }
        }
    }
}

// MARK: - AVPlayerView

extension AVMediaPlayerProxy {

    struct AVPlayerView: UIViewRepresentable {

        @EnvironmentObject
        private var scrubbedSeconds: PublishedBox<Duration>

        let proxy: AVMediaPlayerProxy

        func makeUIView(context: Context) -> UIView {
//            proxy.isScrubbing = context.environment.isScrubbing
            proxy.scrubbedSeconds = $scrubbedSeconds.value
            return UIAVPlayerView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    private class UIAVPlayerView: UIView {

        let proxy: AVMediaPlayerProxy

        init(proxy: AVMediaPlayerProxy) {
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
