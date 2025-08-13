//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import AVKit
import Combine
import JellyfinAPI

// TODO: move to AVPlayerMediaPlayerProxy
// TODO: take isScrubbing, other bindings
class AVPlayerManagerDelegate: NSObject {

    private let manager: MediaPlayerManager
    private var player: AVPlayer?

    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSKeyValueObservation!
    private var timeObserver: Any!
    private var managerEventObserver: AnyCancellable!

    init(manager: MediaPlayerManager) {
        self.manager = manager
        super.init()
        setupAudioSession()
    }

    func set(player: AVPlayer) {
        self.player = player
        if let playbackItem = manager.playbackItem {
            playNew(playbackItem: playbackItem)
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { newTime in
            let newSeconds = Duration.seconds(newTime.seconds)
            self.manager.seconds = newSeconds
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

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }

    private func playbackStopped() {
        player?.pause()
        guard let timeObserver else { return }
        player?.removeTimeObserver(timeObserver)
        rateObserver.invalidate()
        statusObserver.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func playNew(playbackItem: MediaPlayerItem) {
        let newAVPlayerItem = AVPlayerItem(url: playbackItem.url)
        newAVPlayerItem.externalMetadata = playbackItem.baseItem.avMetadata

        player?.replaceCurrentItem(with: newAVPlayerItem)

        rateObserver = player?.observe(\.rate, options: [.new, .initial]) { _, value in
            DispatchQueue.main.async {
                self.manager.set(rate: value.newValue ?? 1.0)
            }
        }

        statusObserver = player?.observe(\.currentItem?.status, options: [.new, .initial]) { _, value in
            guard let newValue = value.newValue else { return }
            switch newValue {
            case .failed:
                if let error = self.player?.error {
                    DispatchQueue.main.async {
                        self.manager.send(.error(.init("AVPlayer error: \(error.localizedDescription)")))
                    }
                }
            case .readyToPlay: print("AVPlayer ready to play")
            case .unknown: ()
            case .none: ()
            @unknown default: ()
            }
        }
    }

    deinit {
        playbackStopped()
        deactivateAudioSession()
    }
}
