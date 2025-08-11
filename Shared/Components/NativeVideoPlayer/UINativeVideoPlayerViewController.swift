//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import Defaults
import JellyfinAPI
import Logging
import SwiftUI

class UINativeVideoPlayerViewController: AVPlayerViewController {

    private let logger = Logger.swiftfin()
    private let manager: MediaPlayerManager

    private let isScrubbing: Binding<Bool>
    private let scrubbedSeconds: Binding<Duration>

    private var managerEventObserver: AnyCancellable!

    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSKeyValueObservation!
    private var timeObserver: Any!

    init(
        manager: MediaPlayerManager,
        isScrubbing: Binding<Bool>,
        scrubbedSeconds: Binding<Duration>
    ) {

//        let videoPlayerProxy = AVPlayerMediaPlayerProxy()
//        manager.proxy = videoPlayerProxy

//        self.proxy = manager.proxy as! AVPlayerMediaPlayerProxy
        self.manager = manager
        self.scrubbedSeconds = scrubbedSeconds
        self.isScrubbing = isScrubbing

        super.init(nibName: nil, bundle: nil)

        let newPlayer: AVPlayer = .init()

        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false
        allowsPictureInPicturePlayback = true
        allowsVideoFrameAnalysis = false
        showsPlaybackControls = false

        #if !os(tvOS)
        updatesNowPlayingInfoCenter = false
        #endif

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { newTime in
            let newSeconds = Duration.seconds(newTime.seconds)

            if !isScrubbing.wrappedValue {
                scrubbedSeconds.wrappedValue = newSeconds
            }
            manager.seconds = newSeconds
        }

        player = newPlayer
        ((manager.proxy as! AnyMediaPlayerProxy).proxy as! AVPlayerMediaPlayerProxy)
            .avPlayer = player

//        proxy.avPlayer = player

        if let playbackItem = manager.playbackItem {
            playNew(playbackItem: playbackItem)
        }

        managerEventObserver = manager.events
            .sink { event in
                switch event {
                case .playbackStopped:
                    self.playbackStopped()
                case let .itemChanged(playbackItem):
                    self.playNew(playbackItem: playbackItem)
                }
            }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func playbackStopped() {
        player?.pause()
        guard let timeObserver else { return }
        player?.removeTimeObserver(timeObserver)
        rateObserver.invalidate()
        statusObserver.invalidate()
    }

    private func playNew(playbackItem: MediaPlayerItem) {
//        Task {
        let newAVPlayerItem = AVPlayerItem(url: playbackItem.url)
        newAVPlayerItem.externalMetadata = playbackItem.baseItem.avMetadata
        print("Playing new item: \(playbackItem.url)")

//            do {
//                _ = try await newAVPlayerItem.asset.load(.duration, .tracks, .isPlayable)
//            } catch {
//                await MainActor.run {
//                    manager.send(.error(.init("Unable to load AVPlayer item")))
//                }
//                return
//            }

        let startSeconds = max(
            .zero,
            (playbackItem.baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset])
        )

//            await MainActor.run {
        player?.replaceCurrentItem(with: newAVPlayerItem)
//        seek(to: startSeconds)
//            }
//        }

        rateObserver = player?.observe(\.rate, options: [.new, .initial]) { _, value in
            DispatchQueue.main.async {
                self.manager.set(rate: value.newValue ?? 1.0)
            }
        }

        statusObserver = player?.observe(\.currentItem?.status, options: [.new, .initial]) { _, value in
            print(value)
            guard let newValue = value.newValue else { return }
            switch newValue {
            case .failed: print("AVPlayer failed with error: \(String(describing: self.player?.error))")
            case .readyToPlay: print("AVPlayer ready to play")
            case .unknown: ()
            case .none: ()
            @unknown default: ()
            }
        }
    }

    private func seek(to seconds: Duration) {
        player?.seek(
            to: CMTime(seconds: seconds.seconds, preferredTimescale: 1),
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: { _ in
                self.manager.proxy?.play()
//                self.proxy.play()
            }
        )
    }
}
