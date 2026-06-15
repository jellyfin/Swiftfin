//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import AVKit
import Defaults
import Foundation
@preconcurrency import JellyfinAPI
import SwiftUI

@MainActor
class AVMediaPlayerProxy: NSObject,
    VideoMediaPlayerProxy,
    MediaPlayerPictureInPictureCapable,
    MediaPlayerPlaybackInfoProvider,
    AirPlayable,
    PictureInPictureable
{

    var supportsAirPlay: Bool {
        true
    }

    var airPlayPlayerType: VideoPlayerType? {
        nil
    }

    var supportsPiP: Bool {
        true
    }

    var pipPlayerType: VideoPlayerType? {
        nil
    }

    let videoPlayerType: VideoPlayerType = .avPlayer

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let playbackInfo: PublishedBox<MediaPlayerPlaybackInfo?> = .init(initialValue: nil)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)

    let isPiPActive: PublishedBox<Bool> = .init(initialValue: false)
    let isPiPAvailable: PublishedBox<Bool> = .init(initialValue: false)

    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

    private(set) var pipController: AVPictureInPictureController?

    private var pendingSeekSeconds: Duration?
    private var transcodeStartOffset: Duration = .zero

    private var cachedAudioStreams: [MediaStream] = []
    private var cachedSubtitleStreams: [MediaStream] = []
    private var cachedAudioGroup: AVMediaSelectionGroup?
    private var cachedSubtitleGroup: AVMediaSelectionGroup?

    private var pipAvailableObserver: NSKeyValueObservation?
    private var externalPlaybackObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlStatusObserver: NSKeyValueObservation?
    private var videoSizeObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var itemEndObserver: NSObjectProtocol?
    private var accessLogObserver: NSObjectProtocol?

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }
        }
    }

    var observers: [any MediaPlayerObserver] = [
        NowPlayableObserver(),
    ]

    override init() {
        self.player = AVPlayer()
        self.avPlayerLayer = AVPlayerLayer(player: player)

        super.init()

        player.appliesMediaSelectionCriteriaAutomatically = false

        #if os(iOS)
        player.usesExternalPlaybackWhileExternalScreenIsActive = true
        #endif

        externalPlaybackObserver = player.observe(
            \.isExternalPlaybackActive,
            options: [.initial, .new]
        ) { [weak self] player, _ in

            let isActive = player.isExternalPlaybackActive

            Task { @MainActor [weak self] in
                self?.manager?.remote.setAirPlayActive(isActive)
            }
        }

        addTimeObserver()
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
        guard player.currentItem?.status == .readyToPlay else {
            setSeconds((manager?.seconds ?? .zero) + seconds)
            return
        }

        let currentTime = player.currentTime()
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 1)

        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        guard player.currentItem?.status == .readyToPlay else {
            setSeconds(max(.zero, (manager?.seconds ?? .zero) - seconds))
            return
        }

        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 1))

        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setRate(_ rate: Float) {
        // `play()` applies the rate when playback resumes while setting one during a pause forces a resume
        guard player.rate != 0 else { return }
        player.rate = rate
    }

    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)? = nil) {
        guard player.currentItem?.status == .readyToPlay else {
            pendingSeekSeconds = seconds
            completion?(true)
            return
        }

        let relative = max(.zero, seconds - transcodeStartOffset)
        let time = CMTime(seconds: relative.seconds, preferredTimescale: 1)

        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            completion?(finished)
        }
    }

    func setAudioStream(_ stream: MediaStream) {
        guard let item = player.currentItem,
              let group = cachedAudioGroup
        else { return }

        let targetIndex = stream.index ?? -1

        guard let option = selectionOption(matching: targetIndex, in: group, from: cachedAudioStreams) else { return }

        item.select(option, in: group)
    }

    func setSubtitleStream(_ stream: MediaStream) {
        guard let item = player.currentItem,
              let group = cachedSubtitleGroup
        else { return }

        let targetIndex = stream.index ?? -1

        if targetIndex == -1 {
            item.select(nil, in: group)
            return
        }

        guard let option = selectionOption(matching: targetIndex, in: group, from: cachedSubtitleStreams) else { return }

        item.select(option, in: group)
    }

    func setAspectFill(_ aspectFill: Bool) {
        avPlayerLayer.videoGravity = aspectFill ? .resizeAspectFill : .resizeAspect
    }

    private func selectionOption(
        matching index: Int,
        in group: AVMediaSelectionGroup,
        from streams: [MediaStream]
    ) -> AVMediaSelectionOption? {
        if streams.count == group.options.count,
           let position = streams.firstIndex(where: { $0.index == index })
        {
            return group.options[position]
        }

        if group.options.count == 1 {
            return group.options.first
        }

        if let language = streams.first(where: { $0.index == index })?.language {
            return AVMediaSelectionGroup.mediaSelectionOptions(
                from: group.options,
                filteredAndSortedAccordingToPreferredLanguages: [language]
            ).first
        }

        return nil
    }

    @ViewBuilder
    var videoPlayerBody: some View {
        AVPlayerView()
            .environmentObject(self)
    }
}

// MARK: - Picture In Picture

extension AVMediaPlayerProxy {

    func setupPiP() {
        guard pipController == nil, AVPictureInPictureController.isPictureInPictureSupported() else { return }

        pipController = AVPictureInPictureController(playerLayer: avPlayerLayer)
        pipController?.delegate = self
        pipController?.requiresLinearPlayback = false

        #if os(iOS)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        #endif

        pipAvailableObserver = pipController?.observe(
            \.isPictureInPicturePossible,
            options: [.initial, .new]
        ) { [weak self] controller, _ in
            let isAvailable = controller.isPictureInPicturePossible
            DispatchQueue.main.async {
                self?.isPiPAvailable.value = isAvailable
            }
        }
    }

    func startPiP() {
        pipController?.startPictureInPicture()
    }

    func stopPiP() {
        pipController?.stopPictureInPicture()
    }

    private func teardownPiP() {
        if isPiPActive.value {
            pipController?.stopPictureInPicture()
        }

        isPiPActive.value = false
        isPiPAvailable.value = false

        pipAvailableObserver?.invalidate()
        pipAvailableObserver = nil
    }
}

extension AVMediaPlayerProxy: AVPictureInPictureControllerDelegate {

    nonisolated func pictureInPictureControllerDidStartPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            isPiPActive.value = true
        }
    }

    nonisolated func pictureInPictureControllerDidStopPictureInPicture(_ controller: AVPictureInPictureController) {
        Task { @MainActor in
            isPiPActive.value = false
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Task { @MainActor in
            isPiPActive.value = false
            manager?.logger.error("Unable to start Picture in Picture: \(error.localizedDescription)")
        }
    }

    nonisolated func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}

// MARK: - Playback Lifecycle

extension AVMediaPlayerProxy {

    func playNew(item: MediaPlayerItem) {
        let playerItem = AVPlayerItem(url: item.url)
        playerItem.externalMetadata = item.baseItem.avMetadata

        removeItemObservers()
        addTimeObserver()

        pendingSeekSeconds = nil
        transcodeStartOffset = item.transcodeStartOffset

        cachedAudioStreams = item.audioStreams.filter { $0.isExternal != true }
        cachedSubtitleStreams = item.subtitleStreams.filter { $0.isExternal != true }

        player.replaceCurrentItem(with: playerItem)

        observeTimeControlStatus()
        observeVideoSize(of: playerItem)
        observeItemEnd(of: playerItem)
        observeAccessLog(of: playerItem)
        observeStatus(of: playerItem, for: item)
    }

    func playbackStopped() {
        teardownPiP()

        pendingSeekSeconds = nil

        player.pause()

        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        removeItemObservers()
    }

    private func addTimeObserver() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1000),
            queue: .main
        ) { [weak self] newTime in
            MainActor.assumeIsolated {
                guard let self, newTime.isNumeric else { return }

                let newSeconds = Duration.seconds(newTime.seconds) + self.transcodeStartOffset

                if !self.isScrubbing.wrappedValue {
                    self.scrubbedSeconds.wrappedValue = newSeconds
                }

                self.manager?.seconds = newSeconds
            }
        }
    }

    private func removeItemObservers() {
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

    private func observeTimeControlStatus() {
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
    }

    private func observeVideoSize(of playerItem: AVPlayerItem) {
        videoSizeObserver = playerItem.observe(\.presentationSize, options: [.new]) { [weak self] playerItem, _ in
            guard let self else { return }

            DispatchQueue.main.async {
                let size = playerItem.presentationSize
                if size != .zero {
                    self.videoSize.value = size
                }
            }
        }
    }

    private func observeItemEnd(of playerItem: AVPlayerItem) {
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !(self.manager?.playbackItem?.baseItem.isLiveStream ?? false) else { return }

                if let runtime = self.manager?.item.runtime {
                    self.manager?.seconds = runtime
                } else if let duration = self.player.currentItem?.duration, duration.isNumeric {
                    self.manager?.seconds = Duration.seconds(duration.seconds)
                }

                self.manager?.ended()
            }
        }
    }

    private func observeAccessLog(of playerItem: AVPlayerItem) {
        accessLogObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.newAccessLogEntryNotification,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self,
                      let playerItem = notification.object as? AVPlayerItem,
                      let event = playerItem.accessLog()?.events.last
                else { return }

                let dropped = event.numberOfDroppedVideoFrames >= 0 ? event.numberOfDroppedVideoFrames : nil
                let observed = event.observedBitrate >= 0 ? event.observedBitrate / 1000 : nil
                let indicated = event.indicatedBitrate >= 0 ? event.indicatedBitrate / 1000 : nil
                let bytes = event.numberOfBytesTransferred >= 0 ? event.numberOfBytesTransferred : nil

                if let dropped {
                    self.droppedFrames.value = dropped
                }

                self.playbackInfo.value = MediaPlayerPlaybackInfo(
                    droppedFrames: dropped,
                    observedBitrateKbps: observed,
                    indicatedBitrateKbps: indicated,
                    bytesTransferred: bytes
                )
            }
        }
    }

    private func observeStatus(of playerItem: AVPlayerItem, for item: MediaPlayerItem) {
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] playerItem, _ in
            guard let self else { return }

            switch playerItem.status {
            case .failed:
                let error = playerItem.error ?? self.player.error
                DispatchQueue.main.async {
                    self.manager?.error(ErrorMessage("AVPlayer error: \(error?.localizedDescription ?? L10n.unknownError)"))
                }
            case .readyToPlay:
                Task { @MainActor [weak self] in
                    await self?.itemDidBecomeReady(playerItem: playerItem, item: item)
                }
            default: ()
            }
        }
    }

    private func itemDidBecomeReady(playerItem: AVPlayerItem, item: MediaPlayerItem) async {
        let startSeconds = pendingSeekSeconds ?? max(
            .zero,
            (item.baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset])
        )
        pendingSeekSeconds = nil

        let relativeStart = max(.zero, startSeconds - transcodeStartOffset)

        manager?.logger.info(
            "⏱ avReady: baseStart=\(item.baseItem.startSeconds?.seconds ?? -1)s startSeconds=\(startSeconds.seconds)s offset=\(self.transcodeStartOffset.seconds)s → relativeSeek=\(relativeStart.seconds)s url=\(item.url.absoluteString)"
        )

        cachedAudioGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .audible)
        cachedSubtitleGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible)

        setAudioStream(.init(index: item.selectedAudioStreamIndex))
        setSubtitleStream(.init(index: item.selectedSubtitleStreamIndex ?? -1))

        player.seek(
            to: CMTimeMake(value: relativeStart.components.seconds, timescale: 1),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        ) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self,
                      let manager = self.manager,
                      manager.state != .stopped,
                      manager.playbackRequestStatus == .playing
                else { return }

                self.player.rate = manager.rate
            }
        }
    }
}

// MARK: - AVPlayerView

extension AVMediaPlayerProxy {

    struct AVPlayerView: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var proxy: AVMediaPlayerProxy

        var body: some View {
            AVPlayerLayerView(proxy: proxy)
                .onReceive(manager.$playbackItem) { playbackItem in
                    guard let playbackItem else { return }
                    proxy.playNew(item: playbackItem)
                }
                .onReceive(manager.$state) { state in
                    guard state == .stopped else { return }
                    proxy.playbackStopped()
                }
                .backport
                .onChange(of: manager.rate) { _, newValue in
                    proxy.setRate(newValue)
                }
        }
    }

    private struct AVPlayerLayerView: UIViewRepresentable {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        let proxy: AVMediaPlayerProxy

        func makeUIView(context: Context) -> UIView {
            proxy.isScrubbing = Binding(
                get: { containerState.isScrubbing },
                set: { containerState.isScrubbing = $0 }
            )
            proxy.scrubbedSeconds = Binding(
                get: { containerState.scrubbedSeconds.value },
                set: { containerState.scrubbedSeconds.value = $0 }
            )

            return AVPlayerUIView(proxy: proxy)
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    private class AVPlayerUIView: UIView {

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
