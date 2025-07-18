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
import Factory
import JellyfinAPI
import Logging
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

    private let logger = Logger.swiftfin()

    private var rateObserver: NSKeyValueObservation!
    private var statusObserver: NSKeyValueObservation!
    private var timeObserverToken: Any!
    private var hasReportedError = false
    private var asset: AVAsset?
    private var isShowingAlert = false

    init(manager: VideoPlayerManager) {

        self.videoPlayerManager = manager

        super.init(nibName: nil, bundle: nil)

        // Create asset and player item properly
        let url = manager.currentViewModel.playbackURL
        asset = AVAsset(url: url)

        // Load asset properties before creating player item
        guard let asset = asset else { return }

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.externalMetadata = createMetadata()

        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.allowsExternalPlayback = true
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false

        // enable pip
        allowsPictureInPicturePlayback = true

        // Observe player item status for error detection
        statusObserver = newPlayer.observe(\.currentItem?.status, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self,
                  let status = player.currentItem?.status else { return }

            switch status {
            case .readyToPlay:
                self.hasReportedError = false
            case .failed:
                if !self.hasReportedError {
                    self.hasReportedError = true
                    let error = player.currentItem?.error
                    let nsError = error as NSError?
                    logger.error("Native player failed to load", metadata: [
                        "error": "\(error?.localizedDescription ?? "Unknown error")",
                        "code": "\(nsError?.code ?? -1)",
                        "domain": "\(nsError?.domain ?? "unknown")",
                        "userInfo": "\(nsError?.userInfo ?? [:])",
                    ])

                    // Report error state as stopped to trigger UI update
                    self.videoPlayerManager.onStateUpdated(newState: .stopped)

                    // Show error alert
                    DispatchQueue.main.async {
                        self.showErrorAlert(error: error)
                    }
                }
            case .unknown:
                break
            @unknown default:
                break
            }
        }

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

        // Add external screen support configuration
        player?.usesExternalPlaybackWhileExternalScreenIsActive = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
        guard let timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)

        // Clean up observers
        rateObserver?.invalidate()
        statusObserver?.invalidate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Load asset properties before playing
        loadAssetAndPlay()
    }

    private func loadAssetAndPlay() {
        guard let asset = asset else {
            showErrorAlert(error: nil)
            return
        }

        let keys = ["playable", "duration", "tracks"]
        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                var error: NSError?
                for key in keys {
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status == .failed {
                        self.logger.error("Failed to load asset key", metadata: [
                            "key": "\(key)",
                            "error": "\(error?.localizedDescription ?? "Unknown error")",
                        ])
                        self.showErrorAlert(error: error)
                        return
                    }
                }

                if !asset.isPlayable {
                    self.logger.error("Asset is not playable")
                    self.showErrorAlert(error: NSError(
                        domain: "VideoPlayer",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "This video format is not supported"]
                    ))
                    return
                }

                // Asset is ready, seek and play
                self.player?.seek(
                    to: CMTimeMake(
                        value: Int64(self.videoPlayerManager.currentViewModel.item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]),
                        timescale: 1
                    ),
                    toleranceBefore: .zero,
                    toleranceAfter: .zero,
                    completionHandler: { _ in
                        self.play()
                    }
                )
            }
        }
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

    private func showErrorAlert(error: Error?) {
        // Prevent multiple alerts
        guard !isShowingAlert else { return }
        isShowingAlert = true

        var errorMessage = "The video could not be played."

        if let nsError = error as NSError? {
            switch nsError.code {
            case -11850: // AVErrorServerIncorrectlyConfigured
                errorMessage = "The server is not configured to provide video in a format compatible with the native player. Please switch to the Swiftfin player in settings."
            case -11800: // AVErrorUnknown
                errorMessage = "An unknown playback error occurred. Please try again or switch to the Swiftfin player."
            case -11819: // AVErrorMediaServicesWereReset
                errorMessage = "Media services were reset. Please try again."
            case -11839: // AVErrorDecoderNotFound
                errorMessage = "This video format is not supported by the native player. Please switch to the Swiftfin player."
            default:
                errorMessage = error?.localizedDescription ?? "The video could not be played. Please check your network connection or try a different video format."
            }
        }

        let alert = UIAlertController(
            title: "Native Player Error",
            message: errorMessage,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.isShowingAlert = false
            self?.dismiss(animated: true)
        })

        // Check if we can present the alert
        if self.presentedViewController == nil {
            present(alert, animated: true)
        } else {
            // If already presenting, just dismiss
            isShowingAlert = false
            dismiss(animated: true)
        }
    }
}
