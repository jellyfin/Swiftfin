//
//  PlayerViewController.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/12/21.
//

import AVKit
import AVFoundation
import Combine
import Defaults
import JellyfinAPI
import MediaPlayer
import MobileVLCKit
import SwiftUI
import UIKit

// TODO: Make the VLC player layer a view
// This will allow changing media and putting the view somewhere else
// in a compact state, like a small viewer while navigating the app

class VLCPlayerViewController: UIViewController {
    
    // MARK: variables
    
    private var viewModel: VideoPlayerViewModel
    private var vlcMediaPlayer = VLCMediaPlayer()
    private var lastPlayerTicks: Int64 = 0
    private var lastProgressReportTicks: Int64 = 0
    private var cancellables = Set<AnyCancellable>()
    private var overlayDismissTimer: Timer?
    
    private var currentPlayerTicks: Int64 {
        return Int64(vlcMediaPlayer.time.intValue) * 100_000
    }
    
    private var displayingOverlay: Bool {
        return currentOverlayHostingController?.view.alpha ??  0 > 0
    }
    
    private var jumpForwardLength: VideoPlayerJumpLength {
        return Defaults[.videoPlayerJumpForward]
    }

    private var jumpBackwardLength: VideoPlayerJumpLength {
        return Defaults[.videoPlayerJumpBackward]
    }
    
    private lazy var videoContentView = makeVideoContentView()
    private lazy var tapGestureView = makeTapGestureView()
    private var currentOverlayHostingController: UIHostingController<VLCPlayerCompactOverlayView>?
    
    // MARK: init
    
    init(viewModel: VideoPlayerViewModel) {
        
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
        
        viewModel.playerOverlayDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        view.addSubview(videoContentView)
        view.addSubview(tapGestureView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            videoContentView.topAnchor.constraint(equalTo: view.topAnchor),
            videoContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoContentView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate([
            tapGestureView.topAnchor.constraint(equalTo: videoContentView.topAnchor),
            tapGestureView.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
            tapGestureView.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
            tapGestureView.rightAnchor.constraint(equalTo: videoContentView.rightAnchor)
        ])
    }
    
    // MARK: viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        AppUtility.lockOrientation(.all, andRotateTo: .landscapeLeft)
    }
    
    // MARK: viewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        AppUtility.lockOrientation(.all)
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupConstraints()
        
        view.backgroundColor = .black
        
        // These are kept outside of 'setupMediaPlayer' such that
        // they aren't unnecessarily set more than once
        vlcMediaPlayer.delegate = self
        vlcMediaPlayer.drawable = videoContentView
        vlcMediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 14)
        
        setupMediaPlayer(newViewModel: viewModel)
    }
    
    private func changeFill(to shouldFill: Bool) {
        if shouldFill {
            // TODO: May not be possible with current VLCKit
            
//            let drawableView = vlcMediaPlayer.drawable as! UIView
//            let drawableViewSize = drawableView.frame.size
//            let mediaSize = vlcMediaPlayer.videoSize
            
            // Largest size from mediaSize is how it is currently filled
            //     in the drawable view, find scaleFactor by filling entire
            //     drawableView
            
            vlcMediaPlayer.scaleFactor = 1.5
        } else {
            vlcMediaPlayer.scaleFactor = 0
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startPlayback()
    }
    
    // MARK: subviews
    
    private func makeVideoContentView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        
        return view
    }
    
    private func makeTapGestureView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
        rightSwipeGesture.direction = .right
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
        leftSwipeGesture.direction = .left
        
        view.addGestureRecognizer(singleTapGesture)
        view.addGestureRecognizer(rightSwipeGesture)
        view.addGestureRecognizer(leftSwipeGesture)
        
        return view
    }
    
    @objc private func didTap() {
        self.didGenerallyTap()
    }
    
    @objc private func didRightSwipe() {
        self.didSelectForward()
    }
    
    @objc private func didLeftSwipe() {
        self.didSelectBackward()
    }
    
    // MARK: setupOverlayHostingController
    private func setupOverlayHostingController(viewModel: VideoPlayerViewModel) {
        
        if let currentOverlayHostingController = currentOverlayHostingController {
            currentOverlayHostingController.view.isHidden = true
            
            currentOverlayHostingController.view.removeFromSuperview()
            currentOverlayHostingController.removeFromParent()
            self.currentOverlayHostingController = nil
        }
        
        let newOverlayView = VLCPlayerCompactOverlayView(viewModel: viewModel)
        let newOverlayHostingController = UIHostingController(rootView: newOverlayView)
        
        newOverlayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        newOverlayHostingController.view.backgroundColor = UIColor.clear
        addChild(newOverlayHostingController)
        view.addSubview(newOverlayHostingController.view)
        newOverlayHostingController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            newOverlayHostingController.view.topAnchor.constraint(equalTo: videoContentView.topAnchor),
            newOverlayHostingController.view.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
            newOverlayHostingController.view.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
            newOverlayHostingController.view.rightAnchor.constraint(equalTo: videoContentView.rightAnchor)
        ])
        
        self.currentOverlayHostingController = newOverlayHostingController
        
        // There is a behavior when setting this that the navigation bar
        // on the current navigation controller pops up, re-hide it
        self.navigationController?.isNavigationBarHidden = true
    }
}

// MARK: setupMediaPlayer
extension VLCPlayerViewController {
    
    /// Main function that handles setting up the media player with the current VideoPlayerViewModel
    /// and also takes the role of setting the 'viewModel' property with the given viewModel
    ///
    /// Use case for this is setting new media within the same VLCPlayerViewController
    func setupMediaPlayer(newViewModel: VideoPlayerViewModel) {
        
        stopOverlayDismissTimer()
        
        // UX improvement
        (vlcMediaPlayer.drawable as! UIView).isHidden = true
        
        // Stop current media if there is one
        if vlcMediaPlayer.media != nil {
            cancellables.forEach({ $0.cancel() })
            
            vlcMediaPlayer.stop()
            viewModel.sendStopReport()
            viewModel.playerOverlayDelegate = nil
            vlcMediaPlayer.media = nil
        }
        
        lastPlayerTicks = newViewModel.item.userData?.playbackPositionTicks ?? 0
        lastProgressReportTicks = newViewModel.item.userData?.playbackPositionTicks ?? 0

        let media = VLCMedia(url: newViewModel.streamURL)
        media.addOption("--prefetch-buffer-size=1048576")
        media.addOption("--network-caching=5000")
        
        vlcMediaPlayer.media = media
        
        setupOverlayHostingController(viewModel: newViewModel)
        setupViewModelListeners(viewModel: newViewModel)
        
        newViewModel.getAdjacentEpisodes()
        newViewModel.playerOverlayDelegate = self
        
        viewModel = newViewModel
    }
    
    func startPlayback() {
        // UX improvement
        (vlcMediaPlayer.drawable as! UIView).isHidden = false
        
        vlcMediaPlayer.play()
        
        viewModel.sendPlayReport()
        
        restartOverlayDismissTimer()
        
        // 1 second = 10,000,000 ticks
        let startTicks: Int64 = viewModel.item.userData?.playbackPositionTicks ?? 0

        if startTicks != 0 {
            let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
            let secondsScrubbedTo = startTicks / 10_000_000
            let offset = secondsScrubbedTo - Int64(videoPosition)
            if offset > 0 {
                vlcMediaPlayer.jumpForward(Int32(offset))
            } else {
                vlcMediaPlayer.jumpBackward(Int32(abs(offset)))
            }
        }
    }
    
    // MARK: setupViewModelListeners
    
    private func setupViewModelListeners(viewModel: VideoPlayerViewModel) {
        viewModel.$playbackSpeed.sink { newSpeed in
            self.vlcMediaPlayer.rate = Float(newSpeed.rawValue)
        }.store(in: &cancellables)
        
        viewModel.$screenFilled.sink { shouldFill in
            self.changeFill(to: shouldFill)
        }.store(in: &cancellables)
        
        viewModel.$sliderIsScrubbing.sink { sliderIsScrubbing in
            if sliderIsScrubbing {
                self.didBeginScrubbing()
            } else {
                self.didEndScrubbing(position: self.viewModel.sliderPercentage)
            }
        }.store(in: &cancellables)
        
        viewModel.$selectedAudioStreamIndex.sink { newAudioStreamIndex in
            self.didSelectAudioStream(index: newAudioStreamIndex)
        }.store(in: &cancellables)
        
        viewModel.$selectedSubtitleStreamIndex.sink { newSubtitleStreamIndex in
            self.didSelectSubtitleStream(index: newSubtitleStreamIndex)
        }.store(in: &cancellables)
    }
}

// MARK: Show/Hide Overlay
extension VLCPlayerViewController {
    
    private func showOverlay() {
        guard let overlayHostingController = currentOverlayHostingController else { return }
        
        guard overlayHostingController.view.alpha != 1 else { return }
        
        UIView.animate(withDuration: 0.2) {
            overlayHostingController.view.alpha = 1
        }
    }
    
    private func hideOverlay() {
        guard let overlayHostingController = currentOverlayHostingController else { return }
        
        guard overlayHostingController.view.alpha != 0 else { return }
        
        UIView.animate(withDuration: 0.2) {
            overlayHostingController.view.alpha = 0
        }
    }
    
    private func toggleOverlay() {
        guard let overlayHostingController = currentOverlayHostingController else { return }
        
        if overlayHostingController.view.alpha < 1 {
            showOverlay()
        } else {
            hideOverlay()
        }
    }
}

// MARK: OverlayTimer
extension VLCPlayerViewController {
    
    private func restartOverlayDismissTimer(interval: Double = 3) {
        self.overlayDismissTimer?.invalidate()
        self.overlayDismissTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(dismissTimerFired), userInfo: nil, repeats: false)
    }
    
    @objc private func dismissTimerFired() {
        self.hideOverlay()
    }
    
    private func stopOverlayDismissTimer() {
        self.overlayDismissTimer?.invalidate()
    }
}

// MARK: VLCMediaPlayerDelegate
extension VLCPlayerViewController: VLCMediaPlayerDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        
        self.viewModel.playerState = vlcMediaPlayer.state
        
        if vlcMediaPlayer.state == VLCMediaPlayerState.ended {
            didSelectClose()
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        guard !viewModel.sliderIsScrubbing else {
            lastPlayerTicks = currentPlayerTicks
            return
        }
        
        viewModel.sliderPercentage = Double(vlcMediaPlayer.position)
        
        if abs(currentPlayerTicks - lastPlayerTicks) >= 10_000 {
            
            viewModel.playerState = VLCMediaPlayerState.playing
        }
        
        lastPlayerTicks = currentPlayerTicks
        
        if abs(lastProgressReportTicks - currentPlayerTicks) >= 500_000_000 {
            viewModel.sendProgressReport()
            
            lastProgressReportTicks = currentPlayerTicks
        }
    }
}

// MARK: PlayerOverlayDelegate
extension VLCPlayerViewController: PlayerOverlayDelegate {
    
    func didSelectAudioStream(index: Int) {
        vlcMediaPlayer.currentAudioTrackIndex = Int32(index)
    }
    
    func didSelectSubtitleStream(index: Int) {
        vlcMediaPlayer.currentVideoSubTitleIndex = Int32(index)
        
        if index != -1 {
            // set in case weren't shown
            viewModel.subtitlesEnabled = true
        }
    }
    
    func didSelectClose() {
        vlcMediaPlayer.stop()
        
        viewModel.sendStopReport()
        
        dismiss(animated: true, completion: nil)
    }
    
    func didSelectGoogleCast() {
        print("didSelectCast")
    }
    
    func didSelectAirplay() {
        print("didSelectAirplay")
    }
    
    func didSelectCaptions() {
        
        viewModel.subtitlesEnabled = !viewModel.subtitlesEnabled
        
        if viewModel.subtitlesEnabled {
            vlcMediaPlayer.currentVideoSubTitleIndex = vlcMediaPlayer.videoSubTitlesIndexes[1] as! Int32
        } else {
            vlcMediaPlayer.currentVideoSubTitleIndex = -1
        }
    }
    
    // TODO: Implement properly in overlays
    func didSelectMenu() {
        stopOverlayDismissTimer()
    }
    
    // TODO: Implement properly in overlays
    func didDeselectMenu() {
        restartOverlayDismissTimer()
    }
    
    func didSelectBackward() {
        vlcMediaPlayer.jumpBackward(jumpBackwardLength.rawValue)
        
        restartOverlayDismissTimer()
        
        viewModel.sendProgressReport()
        
        self.lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectForward() {
        vlcMediaPlayer.jumpForward(jumpForwardLength.rawValue)
        
        restartOverlayDismissTimer()
        
        viewModel.sendProgressReport()
        
        self.lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectMain() {
        
        switch viewModel.playerState {
        case .buffering:
            vlcMediaPlayer.play()
            restartOverlayDismissTimer()
        case .playing:
            viewModel.sendPauseReport(paused: true)
            vlcMediaPlayer.pause()
            restartOverlayDismissTimer(interval: 5)
        case .paused:
            viewModel.sendPauseReport(paused: false)
            vlcMediaPlayer.play()
        default: ()
        }
    }
    
    func didGenerallyTap() {
        toggleOverlay()
        
        restartOverlayDismissTimer(interval: 5)
    }
    
    func didBeginScrubbing() {
        stopOverlayDismissTimer()
    }
    
    func didEndScrubbing(position: Double) {
        // Necessary math as VLCMediaPlayer doesn't work well
        //     by just setting the position
        let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
        let videoDuration = Double(viewModel.item.runTimeTicks! / 10_000_000)
        let secondsScrubbedTo = round(viewModel.sliderPercentage * videoDuration)
        let newPositionOffset = secondsScrubbedTo - videoPosition
        
        if newPositionOffset > 0 {
            vlcMediaPlayer.jumpForward(Int32(newPositionOffset))
        } else {
            vlcMediaPlayer.jumpBackward(Int32(abs(newPositionOffset)))
        }
        
        restartOverlayDismissTimer()
        
        viewModel.sendProgressReport()
        
        self.lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectPreviousItem() {
        setupMediaPlayer(newViewModel: viewModel.previousItemVideoPlayerViewModel!)
        startPlayback()
    }
    
    func didSelectNextItem() {
        setupMediaPlayer(newViewModel: viewModel.nextItemVideoPlayerViewModel!)
        startPlayback()
    }
}
