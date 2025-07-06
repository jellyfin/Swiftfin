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
import SwiftUI

struct NativeVideoPlayer: View {

    @Environment(\.scenePhase)
    var scenePhase

    @Router
    private var router

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
        .navigationBarHidden(true)
        .statusBarHidden()
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
            }
        }

        player = newPlayer
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure audio session for optimal playback
        configureAudioSession()

        // Add external screen support configuration
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Set category for video playback with audio
            try audioSession.setCategory(
                .playback,
                mode: .moviePlayback,
                options: [.mixWithOthers, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )

            // Configure for optimal performance
            try audioSession.setPreferredSampleRate(48000) // Standard video sample rate
            try audioSession.setPreferredIOBufferDuration(0.005) // 5ms buffer

            // Activate the session
            try audioSession.setActive(true)

        } catch {
            print("Failed to configure audio session in NativeVideoPlayer: \(error)")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
        resetAudioSession()
        guard let timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
    }

    private func resetAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session in NativeVideoPlayer: \(error)")
        }
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
        []

//        let allMetadata: [AVMetadataIdentifier: Any?] = [
//            .commonIdentifierTitle: videoPlayerManager.currentViewModel.item.displayTitle,
//            .iTunesMetadataTrackSubTitle: videoPlayerManager.currentViewModel.item.subtitle,
//        ]
//
//        return allMetadata.compactMap { createMetadataItem(for: $0, value: $1) }
    }

    private func createMetadataItem(
        for identifier: AVMetadataIdentifier,
        value: Any?
    ) -> AVMetadataItem? {
        guard let value else { return nil }
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
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
