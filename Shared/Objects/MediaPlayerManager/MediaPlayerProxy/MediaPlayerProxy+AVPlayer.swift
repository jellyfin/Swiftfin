//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import AVKit
import Combine
import Defaults
import Foundation
@preconcurrency import JellyfinAPI
import SwiftUI

@MainActor
class AVMediaPlayerProxy: NSObject,
    VideoMediaPlayerProxy,
    MediaPlayerPictureInPictureCapable,
    MediaPlayerPlaybackInfoProvider
{

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)
    let playbackInfo: PublishedBox<MediaPlayerPlaybackInfo?> = .init(initialValue: nil)
    var videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

    private(set) var pipController: AVPictureInPictureController?

    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var videoSizeObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var accessLogObserver: NSObjectProtocol?
    private var managerItemObserver: AnyCancellable?
    private var managerStateObserver: AnyCancellable?

    private var cachedAudioStreams: [MediaStream] = []
    private var cachedSubtitleStreams: [MediaStream] = []
    private var cachedAudioGroup: AVMediaSelectionGroup?
    private var cachedSubtitleGroup: AVMediaSelectionGroup?

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }

            if let manager {
                managerItemObserver = manager.$playbackItem
                    .sink { [weak self] playbackItem in
                        if let playbackItem {
                            self?.playNew(item: playbackItem)
                        }
                    }

                managerStateObserver = manager.$state
                    .sink { [weak self] state in
                        switch state {
                        case .stopped:
                            self?.playbackStopped()
                        default: break
                        }
                    }
            } else {
                managerItemObserver?.cancel()
                managerStateObserver?.cancel()
            }
        }
    }

    override init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)
        super.init()

        player.appliesMediaSelectionCriteriaAutomatically = false
        addTimeObserver()
    }

    /// Registers the periodic time observer that drives the progress bar and
    /// manager seconds. Safe to call multiple times — removes any existing
    /// observer before adding a new one.
    private func addTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] newTime in
            guard let self, newTime.isNumeric else { return }
            let newSeconds = Duration.seconds(newTime.seconds)
            if !isScrubbing.wrappedValue {
                scrubbedSeconds.wrappedValue = newSeconds
            }
            manager?.seconds = newSeconds
        }
    }

    func play() {
        player.rate = manager?.rate ?? 1.0
    }

    func pause() {
        player.pause()
    }

    func stop() {
        player.pause()
    }

    func jumpForward(_ seconds: Duration) {
        guard player.currentItem?.status == .readyToPlay else { return }
        let currentTime = player.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        guard player.currentItem?.status == .readyToPlay else { return }
        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))
        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {
        // Only update the live rate when currently playing; play() applies the
        // desired rate when playback resumes so the player stays paused if paused.
        guard player.rate != 0 else { return }
        player.rate = rate
    }

    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)? = nil) {
        guard player.currentItem?.status == .readyToPlay else {
            completion?(false)
            return
        }
        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 1)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            completion?(finished)
        }
    }

    func setAspectFill(_ aspectFill: Bool) {
        avPlayerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }

    func setAudioStream(_ stream: MediaStream) {
        guard let item = player.currentItem,
              let group = cachedAudioGroup else { return }
        let targetIndex = stream.index ?? -1
        guard let matchingOptionIndex = cachedAudioStreams.firstIndex(where: { $0.index == targetIndex }),
              matchingOptionIndex < group.options.count else { return }
        item.select(group.options[matchingOptionIndex], in: group)
    }

    func setSubtitleStream(_ stream: MediaStream) {
        guard let item = player.currentItem,
              let group = cachedSubtitleGroup else { return }
        let targetIndex = stream.index ?? -1
        if targetIndex == -1 {
            item.select(nil, in: group)
            return
        }
        guard let matchingOptionIndex = cachedSubtitleStreams.firstIndex(where: { $0.index == targetIndex }),
              matchingOptionIndex < group.options.count else { return }
        item.select(group.options[matchingOptionIndex], in: group)
    }

    var videoPlayerBody: some View {
        AVPlayerWrapperView()
            .environmentObject(self)
    }
}

// MARK: - PiP

extension AVMediaPlayerProxy {

    func setupPiP() {
        guard pipController == nil, AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pipController = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pipController?.delegate = self
        pipController?.requiresLinearPlayback = false
        #if !os(tvOS)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        #endif
    }

    func startPiP() {
        pipController?.startPictureInPicture()
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
}

extension AVMediaPlayerProxy: AVPictureInPictureControllerDelegate {

    nonisolated func pictureInPictureControllerWillStartPictureInPicture(_ controller: AVPictureInPictureController) {}
    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {}
    nonisolated func pictureInPictureControllerWillStopPictureInPicture(_ controller: AVPictureInPictureController) {}
    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {}

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {}

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

// MARK: - Playback lifecycle

extension AVMediaPlayerProxy {

    private func playbackStopped() {
        player.pause()

        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        statusObserver?.invalidate()
        statusObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        videoSizeObserver?.invalidate()
        videoSizeObserver = nil

        if let itemEndObserver {
            NotificationCenter.default.removeObserver(itemEndObserver)
            self.itemEndObserver = nil
        }
        if let accessLogObserver {
            NotificationCenter.default.removeObserver(accessLogObserver)
            self.accessLogObserver = nil
        }

        cachedAudioGroup = nil
        cachedSubtitleGroup = nil
        playbackInfo.value = nil
    }

    private func playNew(item: MediaPlayerItem) {
        let baseItem = item.baseItem

        let newAVPlayerItem = AVPlayerItem(url: item.url)
        newAVPlayerItem.externalMetadata = item.baseItem.avMetadata

        // Ensure the time observer is active for the new item
        addTimeObserver()

        statusObserver?.invalidate()
        videoSizeObserver?.invalidate()
        timeControlStatusObserver?.invalidate()
        if let itemEndObserver {
            NotificationCenter.default.removeObserver(itemEndObserver)
        }
        if let accessLogObserver {
            NotificationCenter.default.removeObserver(accessLogObserver)
        }
        cachedAudioGroup = nil
        cachedSubtitleGroup = nil
        playbackInfo.value = nil

        // Cache stream lists for track selection mapping
        cachedAudioStreams = item.audioStreams
        cachedSubtitleStreams = item.subtitleStreams

        player.replaceCurrentItem(with: newAVPlayerItem)

        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self else { return }
            let status = player.timeControlStatus
            DispatchQueue.main.async {
                switch status {
                case .waitingToPlayAtSpecifiedRate:
                    self.isBuffering.value = true
                case .playing:
                    self.isBuffering.value = false
                    self.manager?.setPlaybackRequestStatus(status: .playing)
                case .paused:
                    self.isBuffering.value = false
                    self.manager?.setPlaybackRequestStatus(status: .paused)
                @unknown default: ()
                }
            }
        }

        videoSizeObserver = newAVPlayerItem.observe(\.presentationSize, options: [.new]) { [weak self] playerItem, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                let size = playerItem.presentationSize
                if size != .zero {
                    self.videoSize.value = size
                }
            }
        }

        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newAVPlayerItem,
            queue: .main
        ) { [weak self] _ in
            guard let self, !(self.manager?.playbackItem?.baseItem.isLiveStream ?? false) else { return }

            if let runtime = self.manager?.item.runtime {
                self.manager?.seconds = runtime
            } else if let duration = self.player.currentItem?.duration, duration.isNumeric {
                self.manager?.seconds = Duration.seconds(duration.seconds)
            }
            self.manager?.ended()
        }

        accessLogObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.newAccessLogEntryNotification,
            object: newAVPlayerItem,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let playerItem = notification.object as? AVPlayerItem,
                  let event = playerItem.accessLog()?.events.last else { return }

            let dropped = event.numberOfDroppedVideoFrames >= 0 ? event.numberOfDroppedVideoFrames : nil
            let observed = event.observedBitrate >= 0 ? event.observedBitrate / 1000 : nil
            let indicated = event.indicatedBitrate >= 0 ? event.indicatedBitrate / 1000 : nil
            let bytes = event.numberOfBytesTransferred >= 0 ? event.numberOfBytesTransferred : nil

            self.playbackInfo.value = MediaPlayerPlaybackInfo(
                droppedFrames: dropped,
                observedBitrateKbps: observed,
                indicatedBitrateKbps: indicated,
                bytesTransferred: bytes
            )
        }

        statusObserver = newAVPlayerItem.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            guard let self else { return }
            switch playerItem.status {
            case .failed:
                if let error = self.player.error {
                    DispatchQueue.main.async {
                        self.manager?.error(ErrorMessage("AVPlayer error: \(error.localizedDescription)"))
                    }
                }
            case .readyToPlay:
                let startSeconds = max(
                    .zero,
                    (baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset])
                )
                DispatchQueue.main.async {
                    self.cachedAudioGroup = newAVPlayerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .audible)
                    self.cachedSubtitleGroup = newAVPlayerItem.asset.mediaSelectionGroup(forMediaCharacteristic: .legible)

                    self.setAudioStream(.init(index: item.selectedAudioStreamIndex))
                    self.setSubtitleStream(.init(index: item.selectedSubtitleStreamIndex ?? -1))

                    self.player.seek(
                        to: CMTimeMake(value: startSeconds.components.seconds, timescale: 1),
                        toleranceBefore: .zero,
                        toleranceAfter: .zero
                    ) { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.player.rate = self?.manager?.rate ?? 1.0
                        }
                    }
                }
            default: ()
            }
        }
    }
}

// MARK: - AVPlayerView

extension AVMediaPlayerProxy {

    struct AVPlayerView: UIViewRepresentable {

        @EnvironmentObject
        private var proxy: AVMediaPlayerProxy
        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        func makeUIView(context: Context) -> UIView {
            UIAVPlayerView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {
            proxy.isScrubbing = Binding(
                get: { containerState.isScrubbing },
                set: { containerState.isScrubbing = $0 }
            )
            proxy.scrubbedSeconds = Binding(
                get: { containerState.scrubbedSeconds.value },
                set: { containerState.scrubbedSeconds.value = $0 }
            )
        }
    }

    struct AVPlayerWrapperView: View {

        @EnvironmentObject
        private var proxy: AVMediaPlayerProxy
        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            AVPlayerView()
                .backport
                .onChange(of: manager.rate) { _, newRate in
                    proxy.setRate(newRate)
                }
        }
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

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                Task { @MainActor [weak self] in
                    self?.proxy.setupPiP()
                }
            }
        }
    }
}
