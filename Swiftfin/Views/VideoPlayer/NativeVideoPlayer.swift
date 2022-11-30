//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import JellyfinAPI
import SwiftUI

struct NativeVideoPlayer: View {
    
    @EnvironmentObject
    private var router: ItemVideoPlayerCoordinator.Router
    
    @ObservedObject
    private var videoPlayerManager: NativeVideoPlayerManager
    
    init(manager: NativeVideoPlayerManager) {
        self.videoPlayerManager = manager
    }
    
    @ViewBuilder
    private func playerView(with viewModel: NativeVideoPlayerViewModel) -> some View {
        Text("todo")
//        NativeVideoPlayerView(manager: videoPlayerManager, viewModel: viewModel)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.black

            VStack {
                ProgressView()

                Button {
                    router.dismissCoordinator()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    var body: some View {
        Group {
            if let viewModel = videoPlayerManager.viewModel {
                playerView(with: viewModel)
            } else {
                loadingView
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
    }
}

struct NativeVideoPlayerView: UIViewControllerRepresentable {
    
    let videoPlayerManager: NativeVideoPlayerManager
    let viewModel: NativeVideoPlayerViewModel
    
//    init(manager: NativeVideoPlayerManager, viewModel: NativeVideoPlayerViewModel) {
//        self.videoPlayerManager = manager
//        self.viewModel = viewModel
//    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        UINativeVideoPlayerViewController(manager: videoPlayerManager, viewModel: viewModel)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class UINativeVideoPlayerViewController: AVPlayerViewController {

    let videoPlayerManager: NativeVideoPlayerManager
    let viewModel: NativeVideoPlayerViewModel

//    var timeObserverToken: Any?

    var lastProgressTicks: Int64 = 0

    init(manager: NativeVideoPlayerManager, viewModel: NativeVideoPlayerViewModel) {

        self.videoPlayerManager = manager
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        let player: AVPlayer = .init(url: viewModel.playbackURL)

        player.appliesMediaSelectionCriteriaAutomatically = false
        player.currentItem?.externalMetadata = createMetadata()
        
//        var isHdrVideo = false
//            let pVideoTrack = AVAsset(url: URL(fileURLWithPath: assetURL!))
//            if #available(iOS 14.0, *) {
//                let tracks = pVideoTrack.tracks(withMediaCharacteristic: .containsHDRVideo)
//                for track in tracks{
//                    isHdrVideo = track.hasMediaCharacteristic(.containsHDRVideo)
//                    if(isHdrVideo){
//                        break
//                    }
//                }
//            }
        
//        self.showsPlaybackControls = false

//        let timeScale = CMTimeScale(NSEC_PER_SEC)
//        let time = CMTime(seconds: 5, preferredTimescale: timeScale)

//        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
//            if time.seconds != 0 {
//                self?.sendProgressReport(seconds: time.seconds)
//            }
//        }

        self.player = player

        self.allowsPictureInPicturePlayback = true
        self.player?.allowsExternalPlayback = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        stop()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        player?.seek(
            to: CMTimeMake(value: Int64(viewModel.item.startTimeSeconds), timescale: 1),
            toleranceBefore: CMTimeMake(value: 1, timescale: 1),
            toleranceAfter: CMTimeMake(value: 1, timescale: 1),
            completionHandler: { _ in
                self.play()
            }
        )
    }
    
    private func createMetadata() -> [AVMetadataItem] {
        let allMetadata: [AVMetadataIdentifier: Any?] = [
            .commonIdentifierTitle: viewModel.item.displayTitle,
            .iTunesMetadataTrackSubTitle: viewModel.item.subtitle,
        ]

        return allMetadata.compactMap { createMetadataItem(for: $0, value: $1) }
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
    }

    private func stop() {
        self.player?.pause()
    }
}
