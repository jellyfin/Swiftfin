//
//  NativePlayerViewController.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/20/21.
//

import AVKit
import Combine
import JellyfinAPI
import UIKit

class NativePlayerViewController: AVPlayerViewController {
    
    let viewModel: VideoPlayerViewModel
    
    private var timeObserverToken: Any?
    
    private var lastProgressTicks: Int64 = 0
    
    init(viewModel: VideoPlayerViewModel) {
        
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    
        let player = AVPlayer(url: viewModel.hlsURL)
        
        player.appliesMediaSelectionCriteriaAutomatically = false
        player.currentItem?.externalMetadata = createMetadata()
        
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 5, preferredTimescale: timeScale)
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
//            print("Timer timed: \(time)")
            
            if time.seconds != 0 {
                self?.sendProgressReport(seconds: time.seconds)
            }
        }
        
        self.player = player
        
        self.allowsPictureInPicturePlayback = true
        self.player?.allowsExternalPlayback = true
    }
    
    private func createMetadata() -> [AVMetadataItem] {
        let allMetadata: [AVMetadataIdentifier: Any] = [
            .commonIdentifierTitle: viewModel.title,
            .iTunesMetadataTrackSubTitle: viewModel.subtitle ?? "",
            .commonIdentifierArtwork: UIImage(data: try! Data(contentsOf: viewModel.item.getBackdropImage(maxWidth: 200)))?.pngData() as Any,
            .commonIdentifierDescription: viewModel.item.overview ?? ""
        ]
        
        return allMetadata.compactMap { createMetadataItem(for:$0, value:$1) }
    }
    
    private func createMetadataItem(for identifier: AVMetadataIdentifier,
                                    value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stop()
        removePeriodicTimeObserver()
    }
    
    func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
     
        player?.seek(to: CMTimeMake(value: viewModel.item.userData?.playbackPositionTicks ?? 0, timescale: 10_000_000), toleranceBefore: CMTimeMake(value: 5, timescale: 1), toleranceAfter: CMTimeMake(value: 5, timescale: 1), completionHandler: { _ in
            self.play()
        })
    }
    
    private func play() {
        player?.play()
        viewModel.sendPlayReport()
    }
    
    private func sendProgressReport(seconds: Double) {
        viewModel.sendProgressReport()
    }
    
    private func stop() {
        viewModel.sendStopReport()
    }
}
