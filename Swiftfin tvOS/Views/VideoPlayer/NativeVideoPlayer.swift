//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct NativeVideoPlayer: View {

    @Environment(\.scenePhase)
    var scenePhase

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private var playerView: some View {
        NativeVideoPlayerView(videoPlayerManager: videoPlayerManager)
    }

    var body: some View {
        Group {
            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
                VideoPlayer.LoadingView()
            }
        }
        .navigationBarHidden()
        .ignoresSafeArea()
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {

    let videoPlayerManager: VideoPlayerManager

    func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
        UINativeVideoPlayerViewController(manager: videoPlayerManager)
    }

    func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
}

class UINativeVideoPlayerViewController: AVPlayerViewController {

    let videoPlayerManager: VideoPlayerManager

    private var rateObserver: NSKeyValueObservation!
    private var timeObserverToken: Any!

    init(manager: VideoPlayerManager) {

        self.videoPlayerManager = manager

        super.init(nibName: nil, bundle: nil)

        let newPlayer: AVPlayer = .init(url: manager.currentViewModel.playbackURL)

        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false
        newPlayer.currentItem?.externalMetadata = createMetadata()

        // enable pip
        allowsPictureInPicturePlayback = true

        rateObserver = newPlayer.observe(\.rate, options: .new) { _, change in
            guard let newValue = change.newValue else { return }

            if newValue == 0 {
                self.videoPlayerManager.onStateUpdated(newState: .paused)
            } else {
                self.videoPlayerManager.playbackSpeed = PlaybackSpeed(rawValue: Double(newValue)) ?? .one
                self.videoPlayerManager.onStateUpdated(newState: .playing)
            }
        }

        let time = CMTime(seconds: 0.1, preferredTimescale: 1000)

        timeObserverToken = newPlayer.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in

            guard let self else { return }

            if time.seconds >= 0 {
                let newSeconds = Int(time.seconds)
                let progress = CGFloat(newSeconds) / CGFloat(self.videoPlayerManager.currentViewModel.item.runTimeSeconds)

                self.videoPlayerManager.currentProgressHandler.progress = progress
                self.videoPlayerManager.currentProgressHandler.scrubbedProgress = progress
                self.videoPlayerManager.currentProgressHandler.seconds = newSeconds
                self.videoPlayerManager.currentProgressHandler.scrubbedSeconds = newSeconds

                videoPlayerManager.nowPlayable.handleNowPlayablePlaybackChange(
                    playing: videoPlayerManager.state == .playing,
                    metadata: .init(
                        rate: 1.0,
                        position: Float(newSeconds),
                        duration: Float(self.videoPlayerManager.currentViewModel.item.runTimeSeconds)
                    )
                )
            }
        }

        player = newPlayer

        let videoPlayerProxy = AVPlayerVideoPlayerProxy()
        videoPlayerProxy.avPlayer = player

        manager.proxy = videoPlayerProxy
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
        videoPlayerManager.nowPlayable.handleNowPlayableSessionEnd()

        guard let timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        player?.seek(
            to: CMTimeMake(
                value: Int64(videoPlayerManager.currentViewModel.item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]),
                timescale: 1
            ),
            toleranceBefore: .zero,
            toleranceAfter: .zero,
            completionHandler: { _ in
                self.play()
            }
        )
    }

    private func createMetadata() -> [AVMetadataItem] {

        let title: String
        var subtitle: String? = nil
        let description = videoPlayerManager.currentViewModel.item.overview

        if videoPlayerManager.currentViewModel.item.type == .episode,
           let seriesName = videoPlayerManager.currentViewModel.item.seriesName
        {
            title = seriesName
            subtitle = videoPlayerManager.currentViewModel.item.displayTitle
        } else {
            title = videoPlayerManager.currentViewModel.item.displayTitle
        }

        return [
            AVMetadataIdentifier.commonIdentifierTitle: title,
            .iTunesMetadataTrackSubTitle: subtitle,
            .commonIdentifierDescription: description,
        ]
            .compactMap(createMetadataItem)
    }

    private func createMetadataItem(
        for identifier: AVMetadataIdentifier,
        value: Any?
    ) -> AVMetadataItem? {
        guard let value else { return nil }

        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"

        return item.copy() as? AVMetadataItem
    }

    private func play() {
        player?.play()

        videoPlayerManager.sendStartReport()
    }

    private func stop() {
        player?.pause()

        videoPlayerManager.sendStopReport()
    }
}
