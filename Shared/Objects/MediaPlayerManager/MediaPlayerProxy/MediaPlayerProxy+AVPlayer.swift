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
    MediaPlayerPictureInPictureCapable
{
    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)
    let videoSize: PublishedBox<CGSize> = .init(initialValue: .zero)
    let droppedFrames: PublishedBox<Int> = .init(initialValue: 0)
    let corruptedFrames: PublishedBox<Int> = .init(initialValue: 0)

    let isPiPActive: PublishedBox<Bool> = .init(initialValue: false)
    let isPiPAvailable: PublishedBox<Bool> = .init(initialValue: false)

    var isScrubbing: Binding<Bool> = .constant(false)
    var scrubbedSeconds: Binding<Duration> = .constant(.zero)

    let avPlayerLayer: AVPlayerLayer
    let player: AVPlayer

    #if os(tvOS)
    weak var displayManager: AVDisplayManager? {
        didSet {
            observeDisplayModeSwitch()
            Task { await updatePreferredDisplayCriteria() }
        }
    }

    private var displayModeSwitchObserver: NSKeyValueObservation?
    #endif

    private(set) var pipController: AVPictureInPictureController?

    private var pendingSeekSeconds: Duration?

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
        let newTime = currentTime + CMTime(seconds: seconds.seconds, preferredTimescale: 600)

        player.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func jumpBackward(_ seconds: Duration) {
        guard player.currentItem?.status == .readyToPlay else {
            setSeconds(max(.zero, (manager?.seconds ?? .zero) - seconds))
            return
        }

        let currentTime = player.currentTime()
        let newTime = max(.zero, currentTime - CMTime(seconds: seconds.seconds, preferredTimescale: 600))

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

        let time = CMTime(seconds: seconds.seconds, preferredTimescale: 600)

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

        #if os(tvOS)
        displayManager?.preferredDisplayCriteria = nil
        #endif

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

                let newSeconds = Duration.seconds(newTime.seconds)

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
    }

    private func observeTimeControlStatus() {
        timeControlStatusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self else { return }

            let status = player.timeControlStatus

            DispatchQueue.main.async {

                #if os(tvOS)
                self.isBuffering.value = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                    || self.displayManager?.isDisplayModeSwitchInProgress == true
                #else
                self.isBuffering.value = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                #endif

                guard self.manager?.remote.isRemotePlayback == false else { return }

                switch status {
                case .playing:
                    self.manager?.setPlaybackRequestStatus(status: .playing)
                case .paused:
                    self.manager?.setPlaybackRequestStatus(status: .paused)
                default:
                    break
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

                if event.numberOfDroppedVideoFrames >= 0 {
                    self.droppedFrames.value = event.numberOfDroppedVideoFrames
                }
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

        cachedAudioGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .audible)
        cachedSubtitleGroup = try? await playerItem.asset.loadMediaSelectionGroup(for: .legible)

        #if os(tvOS)
        await updatePreferredDisplayCriteria()
        #endif

        setAudioStream(.init(index: item.selectedAudioStreamIndex))
        setSubtitleStream(.init(index: item.selectedSubtitleStreamIndex ?? -1))

        player.seek(
            to: CMTime(seconds: startSeconds.seconds, preferredTimescale: 600),
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

    #if os(tvOS)
    private func observeDisplayModeSwitch() {
        guard let displayManager else {
            displayModeSwitchObserver = nil
            return
        }

        displayModeSwitchObserver = displayManager.observe(
            \.isDisplayModeSwitchInProgress,
            options: [.new]
        ) { [weak self] displayManager, _ in
            let inProgress = displayManager.isDisplayModeSwitchInProgress
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    guard let self else { return }

                    guard !inProgress else {
                        self.isBuffering.value = true
                        return
                    }

                    // isDisplayModeSwitchInProgress can be initially blank so wait 0.5 seconds for this to populate
                    // https://developer.apple.com/documentation/avkit/avdisplaymanager/isdisplaymodeswitchinprogress
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        MainActor.assumeIsolated {
                            self.isBuffering.value = self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                                || self.displayManager?.isDisplayModeSwitchInProgress == true
                        }
                    }
                }
            }
        }
    }

    private func updatePreferredDisplayCriteria() async {
        guard let displayManager,
              let playerItem = player.currentItem,
              playerItem.status == .readyToPlay,
              let track = try? await playerItem.asset.loadTracks(withMediaType: .video).first,
              let formatDescription = try? await track.load(.formatDescriptions).first
        else { return }

        let nominalFrameRate = await (try? track.load(.nominalFrameRate)) ?? 0

        displayManager.preferredDisplayCriteria = AVDisplayCriteria(
            refreshRate: nominalFrameRate,
            formatDescription: formatDescription
        )
    }
    #endif
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
            guard let window else { return }

            Task { @MainActor [weak self] in
                self?.proxy.setupPiP()
                #if os(tvOS)
                self?.proxy.displayManager = window.avDisplayManager
                #endif
            }
        }
    }
}
