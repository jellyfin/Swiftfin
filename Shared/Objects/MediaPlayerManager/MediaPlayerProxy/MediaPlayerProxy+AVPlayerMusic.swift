//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)

import AVFoundation
import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
final class AVPlayerMusicMediaPlayerProxy: @preconcurrency VideoMediaPlayerProxy {

    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let player: AVPlayer = .init()
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)

    private var endObserver: AnyCancellable?
    private var managerItemObserver: AnyCancellable?
    private var managerStateObserver: AnyCancellable?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var timeObserver: Any?

    weak var manager: MediaPlayerManager? {
        didSet {
            managerItemObserver?.cancel()
            managerStateObserver?.cancel()

            for var observer in observers {
                observer.manager = manager
            }

            guard let manager else { return }

            managerItemObserver = manager.$playbackItem
                .compactMap(\.self)
                .sink { [weak self] playbackItem in
                    self?.playNew(item: playbackItem)
                }

            managerStateObserver = manager.$state
                .filter { $0 == .stopped }
                .sink { [weak self] _ in
                    self?.stop()
                }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    init() {
        player.allowsExternalPlayback = true
        player.appliesMediaSelectionCriteriaAutomatically = false
        player.automaticallyWaitsToMinimizeStalling = true

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard time.seconds.isFinite else { return }

            Task { @MainActor in
                self?.manager?.seconds = .seconds(max(0, time.seconds))
            }
        }
    }

    func play() {
        player.playImmediately(atRate: manager?.rate ?? 1)
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        invalidateItemObservers()
        isBuffering.value = false
    }

    func jumpForward(_ seconds: Duration) {
        setSeconds(.seconds(player.currentTime().seconds + seconds.seconds))
    }

    func jumpBackward(_ seconds: Duration) {
        setSeconds(.seconds(player.currentTime().seconds - seconds.seconds))
    }

    func setRate(_ rate: Float) {
        guard manager?.playbackRequestStatus == .playing else { return }
        player.rate = rate
    }

    func setAspectFill(_ aspectFill: Bool) {}
    func setAudioStream(_ stream: MediaStream) {}
    func setSubtitleStream(_ stream: MediaStream) {}

    var videoPlayerBody: some View {
        EmptyView()
    }

    func setSeconds(_ seconds: Duration) {
        let runtime = manager?.item.runtime?.seconds ?? .infinity
        let clampedSeconds = min(max(0, seconds.seconds), runtime)
        guard clampedSeconds.isFinite else { return }

        player.seek(
            to: CMTime(seconds: clampedSeconds, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    private func invalidateItemObservers() {
        endObserver?.cancel()
        endObserver = nil
        statusObserver?.invalidate()
        statusObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
    }

    private func playNew(item: MediaPlayerItem) {
        invalidateItemObservers()

        let playerItem = AVPlayerItem(url: item.url)
        playerItem.externalMetadata = item.baseItem.avMetadata
        player.replaceCurrentItem(with: playerItem)

        endObserver = NotificationCenter.default.publisher(
            for: AVPlayerItem.didPlayToEndTimeNotification,
            object: playerItem
        )
        .sink { [weak self] _ in
            if let runtime = self?.manager?.item.runtime {
                self?.manager?.seconds = runtime
            }
            self?.manager?.ended()
        }

        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isBuffering.value = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            }
        }

        statusObserver = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                switch playerItem.status {
                case .failed:
                    let description = playerItem.error?.localizedDescription ?? L10n.unknownError
                    self.manager?.error(ErrorMessage("AVPlayer error: \(description)"))
                case .readyToPlay:
                    let startSeconds = self.manager?.seconds ?? .zero
                    self.player.seek(
                        to: CMTime(seconds: max(0, startSeconds.seconds), preferredTimescale: 600),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero
                    ) { [weak self] _ in
                        DispatchQueue.main.async {
                            guard let self, self.manager?.playbackRequestStatus == .playing else { return }
                            self.play()
                        }
                    }
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

#endif
