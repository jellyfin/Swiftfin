//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import AVKit
import AVFoundation
import Combine
import Defaults
import JellyfinAPI
import MediaPlayer
import TVVLCKit
import SwiftUI
import UIKit

// TODO: Look at making the VLC player layer a view

class VLCPlayerViewController: UIViewController {
    
    // MARK: variables
    
    private var viewModel: VideoPlayerViewModel
    private var vlcMediaPlayer = VLCMediaPlayer()
    private var lastPlayerTicks: Int64 = 0
    private var lastProgressReportTicks: Int64 = 0
    private var viewModelListeners = Set<AnyCancellable>()
    private var overlayDismissTimer: Timer?
    
    private var currentPlayerTicks: Int64 {
        return Int64(vlcMediaPlayer.time.intValue) * 100_000
    }
    
    private var displayingOverlay: Bool {
        return currentOverlayHostingController?.view.alpha ?? 0 > 0
    }
    
    private var displayingContentOverlay: Bool {
        return currentOverlayContentHostingController?.view.alpha ?? 0 > 0
    }
    
    private lazy var videoContentView = makeVideoContentView()
    private lazy var jumpBackwardOverlayView = makeJumpBackwardOverlayView()
    private lazy var jumpForwardOverlayView = makeJumpForwardOverlayView()
    private var currentOverlayHostingController: UIHostingController<tvOSVLCOverlay>?
    private var currentOverlayContentHostingController: UIHostingController<tvOSOverlayContentView>?
    
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
        view.addSubview(jumpForwardOverlayView)
        view.addSubview(jumpBackwardOverlayView)
        
        jumpBackwardOverlayView.alpha = 0
        jumpForwardOverlayView.alpha = 0
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            videoContentView.topAnchor.constraint(equalTo: view.topAnchor),
            videoContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            videoContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
            videoContentView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        NSLayoutConstraint.activate([
            jumpBackwardOverlayView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 300),
            jumpBackwardOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        NSLayoutConstraint.activate([
            jumpForwardOverlayView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -300),
            jumpForwardOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: viewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        didSelectClose()
        
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        defaultNotificationCenter.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    // MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviews()
        setupConstraints()
        
        view.backgroundColor = .black
        
        // Outside of 'setupMediaPlayer' such that they
        // aren't unnecessarily set more than once
        vlcMediaPlayer.delegate = self
        vlcMediaPlayer.drawable = videoContentView
        vlcMediaPlayer.perform(Selector(("setTextRendererFontSize:")), with: 16)
        
        setupMediaPlayer(newViewModel: viewModel)
        
        setupPanGestureRecognizer()
        
        addButtonPressRecognizer(pressType: .menu, action: #selector(didPressMenu))
        
        let defaultNotificationCenter = NotificationCenter.default
        defaultNotificationCenter.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        defaultNotificationCenter.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func appWillTerminate() {
        viewModel.sendStopReport()
    }
    
    @objc private func appWillResignActive() {
        showOverlay()
        
        stopOverlayDismissTimer()
        
        vlcMediaPlayer.pause()
        
        viewModel.sendPauseReport(paused: true)
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
    
    private func makeJumpBackwardOverlayView() -> UIImageView {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 72)
        let forwardSymbolImage = UIImage(systemName: viewModel.jumpBackwardLength.backwardImageLabel, withConfiguration: symbolConfig)
        let imageView = UIImageView(image: forwardSymbolImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }
    
    private func makeJumpForwardOverlayView() -> UIImageView {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 72)
        let forwardSymbolImage = UIImage(systemName: viewModel.jumpForwardLength.forwardImageLabel, withConfiguration: symbolConfig)
        let imageView = UIImageView(image: forwardSymbolImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }
    
    private func setupPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(userPanned(panGestureRecognizer:)))
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    // MARK: pressesBegan
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let buttonPress = presses.first?.type else { return }
             
        switch(buttonPress) {
        case .menu:
           print("Menu")
        case .playPause:
            didSelectMain()
        case .select:
            didGenerallyTap()
        case .upArrow:
           print("Up arrow")
        case .downArrow:
            stopOverlayDismissTimer()

            hideOverlay()
            showOverlayContent()
        case .leftArrow:
            didSelectBackward()
           print("Left arrow")
        case .rightArrow:
            didSelectForward()
        case .pageUp:
            print("page up")
        case .pageDown:
            print("page down")
        @unknown default: ()
        }
    }
    
    private func addButtonPressRecognizer(pressType: UIPress.PressType, action: Selector) {
        let pressRecognizer = UITapGestureRecognizer()
        pressRecognizer.addTarget(self, action: action)
        pressRecognizer.allowedPressTypes = [NSNumber(value: pressType.rawValue)]
        view.addGestureRecognizer(pressRecognizer)
    }
    
    @objc private func didPressMenu() {
        if displayingOverlay {
            hideOverlay()
        } else if displayingContentOverlay {
            hideOverlayContent()
        } else {
            vlcMediaPlayer.pause()
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func userPanned(panGestureRecognizer: UIPanGestureRecognizer) {
        if displayingOverlay {
            restartOverlayDismissTimer()
        }
    }
    
    // MARK: setupOverlayHostingController
    private func setupOverlayHostingController(viewModel: VideoPlayerViewModel) {

        // TODO: Look at injecting viewModel into the environment so it updates the current overlay
        
        // Overlay
        if let currentOverlayHostingController = currentOverlayHostingController {
            // UX fade-out
            UIView.animate(withDuration: 0.5) {
                currentOverlayHostingController.view.alpha = 0
            } completion: { _ in
                currentOverlayHostingController.view.isHidden = true

                currentOverlayHostingController.view.removeFromSuperview()
                currentOverlayHostingController.removeFromParent()
            }
        }

        let newOverlayView = tvOSVLCOverlay(viewModel: viewModel)
        let newOverlayHostingController = UIHostingController(rootView: newOverlayView)

        newOverlayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        newOverlayHostingController.view.backgroundColor = UIColor.clear

        // UX fade-in
        newOverlayHostingController.view.alpha = 0

        addChild(newOverlayHostingController)
        view.addSubview(newOverlayHostingController.view)
        newOverlayHostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            newOverlayHostingController.view.topAnchor.constraint(equalTo: videoContentView.topAnchor),
            newOverlayHostingController.view.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
            newOverlayHostingController.view.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
            newOverlayHostingController.view.rightAnchor.constraint(equalTo: videoContentView.rightAnchor)
        ])

        // UX fade-in
        UIView.animate(withDuration: 0.5) {
            newOverlayHostingController.view.alpha = 1
        }

        self.currentOverlayHostingController = newOverlayHostingController
        
        // OverlayContent
        if let currentOverlayContentHostingController = currentOverlayContentHostingController {
            currentOverlayContentHostingController.view.isHidden = true

            currentOverlayContentHostingController.view.removeFromSuperview()
            currentOverlayContentHostingController.removeFromParent()
        }
        
//        let newSmallMenuOverlayView = SmallMediaStreamSelectionView(items: viewModel.subtitleStreams,
//                                                                    selectedItem: viewModel.subtitleStreams.first(where: { $0.index == viewModel.selectedSubtitleStreamIndex })) { selectedMediaStream in
//            self.didSelectSubtitleStream(index: selectedMediaStream.index ?? -1)
//        }
//        let newOverlayContentHostingController = UIHostingController(rootView: newSmallMenuOverlayView)
        let newOverlayContentView = tvOSOverlayContentView(viewModel: viewModel)
        let newOverlayContentHostingController = UIHostingController(rootView: newOverlayContentView)
        
        newOverlayContentHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        newOverlayContentHostingController.view.backgroundColor = UIColor.clear

        newOverlayContentHostingController.view.alpha = 0

        addChild(newOverlayContentHostingController)
        view.addSubview(newOverlayContentHostingController.view)
        newOverlayContentHostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            newOverlayContentHostingController.view.topAnchor.constraint(equalTo: videoContentView.topAnchor),
            newOverlayContentHostingController.view.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
            newOverlayContentHostingController.view.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
            newOverlayContentHostingController.view.rightAnchor.constraint(equalTo: videoContentView.rightAnchor)
        ])
        
        self.currentOverlayContentHostingController = newOverlayContentHostingController

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
        
        // Stop current media if there is one
        if vlcMediaPlayer.media != nil {
            viewModelListeners.forEach({ $0.cancel() })
            
            vlcMediaPlayer.stop()
            viewModel.sendStopReport()
            viewModel.playerOverlayDelegate = nil
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
        
        let startPercentage = newViewModel.item.userData?.playedPercentage ?? 0
        
        if startPercentage > 0 {
            newViewModel.sliderPercentage = startPercentage / 100
        }
        
        viewModel = newViewModel
    }
    
    // MARK: startPlayback
    func startPlayback() {
        vlcMediaPlayer.play()
        
        setMediaPlayerTimeAtCurrentSlider()
        
        viewModel.sendPlayReport()
        
        restartOverlayDismissTimer(interval: 5)
    }
    
    // MARK: setupViewModelListeners
    
    private func setupViewModelListeners(viewModel: VideoPlayerViewModel) {
        viewModel.$playbackSpeed.sink { newSpeed in
            self.vlcMediaPlayer.rate = Float(newSpeed.rawValue)
        }.store(in: &viewModelListeners)
        
        viewModel.$sliderIsScrubbing.sink { sliderIsScrubbing in
            if sliderIsScrubbing {
                self.didBeginScrubbing()
            } else {
                self.didEndScrubbing()
            }
        }.store(in: &viewModelListeners)
        
        viewModel.$selectedAudioStreamIndex.sink { newAudioStreamIndex in
            self.didSelectAudioStream(index: newAudioStreamIndex)
        }.store(in: &viewModelListeners)
        
        viewModel.$selectedSubtitleStreamIndex.sink { newSubtitleStreamIndex in
            self.didSelectSubtitleStream(index: newSubtitleStreamIndex)
        }.store(in: &viewModelListeners)
        
        viewModel.$subtitlesEnabled.sink { newSubtitlesEnabled in
            self.didToggleSubtitles(newValue: newSubtitlesEnabled)
        }.store(in: &viewModelListeners)
    }
    
    func setMediaPlayerTimeAtCurrentSlider() {
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
        if displayingOverlay {
            hideOverlay()
        } else {
            showOverlay()
        }
    }
    
    private func showOverlayContent() {
        guard let currentOverlayContentHostingController = currentOverlayContentHostingController else { return }
        
        guard currentOverlayContentHostingController.view.alpha != 1 else { return }
        
        currentOverlayContentHostingController.view.setNeedsFocusUpdate()
        currentOverlayContentHostingController.setNeedsFocusUpdate()
        setNeedsFocusUpdate()
        
        UIView.animate(withDuration: 0.2) {
            currentOverlayContentHostingController.view.alpha = 1
        }
    }
    
    private func hideOverlayContent() {
        guard let currentOverlayContentHostingController = currentOverlayContentHostingController else { return }
        
        guard currentOverlayContentHostingController.view.alpha != 0 else { return }
        
        setNeedsFocusUpdate()
        
        UIView.animate(withDuration: 0.2) {
            currentOverlayContentHostingController.view.alpha = 0
        }
    }
}

// MARK: Show/Hide Jump
extension VLCPlayerViewController {
    
    private func flashJumpBackwardOverlay() {
        jumpBackwardOverlayView.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.1) {
            self.jumpBackwardOverlayView.alpha = 1
        } completion: { _ in
            self.hideJumpBackwardOverlay()
        }
    }
    
    private func hideJumpBackwardOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.jumpBackwardOverlayView.alpha = 0
        }
    }
    
    private func flashJumpFowardOverlay() {
        jumpForwardOverlayView.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.1) {
            self.jumpForwardOverlayView.alpha = 1
        } completion: { _ in
            self.hideJumpForwardOverlay()
        }
    }
    
    private func hideJumpForwardOverlay() {
        UIView.animate(withDuration: 0.3) {
            self.jumpForwardOverlayView.alpha = 0
        }
    }
}

// MARK: OverlayTimer
extension VLCPlayerViewController {
    
    private func restartOverlayDismissTimer(interval: Double = 5) {
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
    
    
    // MARK: mediaPlayerStateChanged
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        
        // Don't show buffering if paused, usually here while scrubbing
        if vlcMediaPlayer.state == .buffering && viewModel.playerState == .paused {
            return
        }
        
        viewModel.playerState = vlcMediaPlayer.state
        
        if vlcMediaPlayer.state == VLCMediaPlayerState.ended {
            if viewModel.autoplayEnabled && viewModel.nextItemVideoPlayerViewModel != nil {
                didSelectPlayNextItem()
            } else {
                didSelectClose()
            }
        }
    }
    
    // MARK: mediaPlayerTimeChanged
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        if !viewModel.sliderIsScrubbing {
            viewModel.sliderPercentage = Double(vlcMediaPlayer.position)
        }
        
        viewModel.sliderPercentage = Double(vlcMediaPlayer.position)
        
        // Have to manually set playing because VLCMediaPlayer doesn't
        // properly set it itself
        if abs(currentPlayerTicks - lastPlayerTicks) >= 10_000 {
            viewModel.playerState = VLCMediaPlayerState.playing
        }
        
        // If needing to fix subtitle streams during playback
        if vlcMediaPlayer.currentVideoSubTitleIndex != viewModel.selectedSubtitleStreamIndex && viewModel.subtitlesEnabled {
            didSelectSubtitleStream(index: viewModel.selectedSubtitleStreamIndex)
        }
        
        if vlcMediaPlayer.currentAudioTrackIndex != viewModel.selectedAudioStreamIndex {
            didSelectAudioStream(index: viewModel.selectedAudioStreamIndex)
        }
        
        lastPlayerTicks = currentPlayerTicks
        
        // Send progress report every 5 seconds
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
        
        viewModel.sendProgressReport()
        
        lastProgressReportTicks = currentPlayerTicks
    }
    
    /// Do not call when setting to index -1
    func didSelectSubtitleStream(index: Int) {
        
        viewModel.subtitlesEnabled = true
        vlcMediaPlayer.currentVideoSubTitleIndex = Int32(index)
        
        viewModel.sendProgressReport()
        
        lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectClose() {
        vlcMediaPlayer.stop()
        
        viewModel.sendStopReport()
        
        dismiss(animated: true, completion: nil)
    }
    
    func didToggleSubtitles(newValue: Bool) {
        if newValue {
            vlcMediaPlayer.currentVideoSubTitleIndex = Int32(viewModel.selectedSubtitleStreamIndex)
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
        
        flashJumpBackwardOverlay()
        
        vlcMediaPlayer.jumpBackward(viewModel.jumpBackwardLength.rawValue)
        
        if displayingOverlay {
            restartOverlayDismissTimer()
        }
        
        viewModel.sendProgressReport()
        
        lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectForward() {
        
        flashJumpFowardOverlay()
        
        vlcMediaPlayer.jumpForward(viewModel.jumpForwardLength.rawValue)
        
        if displayingOverlay {
            restartOverlayDismissTimer()
        }
        
        viewModel.sendProgressReport()
        
        lastProgressReportTicks = currentPlayerTicks
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
            restartOverlayDismissTimer()
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
    
    func didEndScrubbing() {
        setMediaPlayerTimeAtCurrentSlider()
        
        restartOverlayDismissTimer()
        
        viewModel.sendProgressReport()
        
        lastProgressReportTicks = currentPlayerTicks
    }
    
    func didSelectPlayPreviousItem() {
        if let previousItemVideoPlayerViewModel = viewModel.previousItemVideoPlayerViewModel {
            setupMediaPlayer(newViewModel: previousItemVideoPlayerViewModel)
            startPlayback()
        }
    }
    
    func didSelectPlayNextItem() {
        if let nextItemVideoPlayerViewModel = viewModel.nextItemVideoPlayerViewModel {
            setupMediaPlayer(newViewModel: nextItemVideoPlayerViewModel)
            startPlayback()
        }
    }
}
