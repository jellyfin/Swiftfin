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
    
    var timeObserverToken: Any?
    
    var lastProgressTicks: Int64 = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: VideoPlayerViewModel) {
        
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    
        let player = AVPlayer(url: viewModel.hlsURL)
        
        player.appliesMediaSelectionCriteriaAutomatically = false
        player.currentItem?.externalMetadata = createMetadata()
        player.currentItem?.navigationMarkerGroups = createNavigationMarkerGroups()
        
//        let chevron = UIImage(systemName: "chevron.right.circle.fill")!
//        let testAction = UIAction(title: "Next", image: chevron) { action in
//            SessionAPI.sendSystemCommand(sessionId: viewModel.response.playSessionId!, command: .setSubtitleStreamIndex)
//                .sink { completion in
//                    print(completion)
//                } receiveValue: { _ in
//                    print("idk but we're here")
//                }
//                .store(in: &self.cancellables)
//        }
        
//        self.transportBarCustomMenuItems = [testAction]
        
//        self.infoViewActions.append(testAction)
        
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
            .commonIdentifierDescription: viewModel.item.overview ?? "",
            .iTunesMetadataContentRating: viewModel.item.officialRating ?? "",
            .quickTimeMetadataGenre: viewModel.item.genres?.first ?? ""
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
    
    private func createNavigationMarkerGroups() -> [AVNavigationMarkersGroup] {
        guard let chapters = viewModel.item.chapters else { return [] }
        
        var metadataGroups: [AVTimedMetadataGroup] = []
        
        // TODO: Determine range between chapters
        chapters.forEach { chapterInfo in
            var chapterMetadata: [AVMetadataItem] = []
            
            let titleItem = createMetadataItem(for: .commonIdentifierTitle, value: chapterInfo.name ?? "No Name")
            chapterMetadata.append(titleItem)
            
            let imageItem = createMetadataItem(for: .commonIdentifierArtwork, value: UIImage(data: try! Data(contentsOf: viewModel.item.getBackdropImage(maxWidth: 200)))?.pngData() as Any)
            chapterMetadata.append(imageItem)
            
            let startTime = CMTimeMake(value: chapterInfo.startPositionTicks ?? 0, timescale: 10_000_000)
            let endTime = CMTimeMake(value: (chapterInfo.startPositionTicks ?? 0) + 50_000_000, timescale: 10_000_000)
            let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
            
            metadataGroups.append(AVTimedMetadataGroup(items: chapterMetadata, timeRange: timeRange))
        }
        
        return [AVNavigationMarkersGroup(title: nil, timedNavigationMarkers: metadataGroups)]
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
        
        viewModel.sendPlayReport(startTimeTicks: viewModel.item.userData?.playbackPositionTicks ?? 0)
    }
    
    private func sendProgressReport(seconds: Double) {
        viewModel.sendProgressReport(ticks: Int64(seconds) * 10_000_000)
    }
    
    private func stop() {
        self.player?.pause()
        viewModel.sendStopReport(ticks: 10_000_000)
    }
}
