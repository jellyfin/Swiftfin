//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import AVKit
import Combine
import Defaults
import JellyfinAPI
import MediaPlayer
import MobileVLCKit
import SwiftUI
import UIKit

// TODO: Look at making the VLC player layer a view

class VLCPlayerViewController: UIViewController {
	// MARK: variables

	private var viewModel: VideoPlayerViewModel
	private var vlcMediaPlayer: VLCMediaPlayer
	private var lastPlayerTicks: Int64 = 0
	private var lastProgressReportTicks: Int64 = 0
	private var viewModelListeners = Set<AnyCancellable>()
	private var overlayDismissTimer: Timer?
	private var isScreenFilled: Bool = false
	private var pinchScale: CGFloat = 1

	private var currentPlayerTicks: Int64 {
		Int64(vlcMediaPlayer.time.intValue) * 100_000
	}

	private var displayingOverlay: Bool {
		currentOverlayHostingController?.view.alpha ?? 0 > 0
	}

	private var displayingChapterOverlay: Bool {
		currentChapterOverlayHostingController?.view.alpha ?? 0 > 0
	}

	private var panBeganBrightness = CGFloat.zero
	private var panBeganVolumeValue = Float.zero
	private var panBeganPoint = CGPoint.zero

	private lazy var videoContentView = makeVideoContentView()
	private lazy var mainGestureView = makeMainGestureView()
	private var currentOverlayHostingController: UIHostingController<VLCPlayerOverlayView>?
	private var currentChapterOverlayHostingController: UIHostingController<VLCPlayerChapterOverlayView>?
	private var systemControlOverlayLabel = UILabel()
	private var currentJumpBackwardOverlayView: UIImageView?
	private var currentJumpForwardOverlayView: UIImageView?
	private var volumeView = MPVolumeView()

	override var keyCommands: [UIKeyCommand]? {
		var commands = [
			UIKeyCommand(title: L10n.playAndPause, action: #selector(didSelectMain), input: " "),
			UIKeyCommand(title: L10n.jumpForward, action: #selector(didSelectForward), input: UIKeyCommand.inputRightArrow),
			UIKeyCommand(title: L10n.jumpBackward, action: #selector(didSelectBackward), input: UIKeyCommand.inputLeftArrow),
			UIKeyCommand(title: L10n.nextItem, action: #selector(didSelectPlayNextItem), input: UIKeyCommand.inputRightArrow,
			             modifierFlags: .command),
			UIKeyCommand(title: L10n.previousItem, action: #selector(didSelectPlayPreviousItem), input: UIKeyCommand.inputLeftArrow,
			             modifierFlags: .command),
			UIKeyCommand(title: L10n.close, action: #selector(didSelectClose), input: UIKeyCommand.inputEscape),
		]
		if let previous = viewModel.playbackSpeed.previous {
			commands.append(.init(title: "\(L10n.playbackSpeed) \(previous.displayTitle)",
			                      action: #selector(didSelectPreviousPlaybackSpeed), input: "[", modifierFlags: .command))
		}
		if let next = viewModel.playbackSpeed.next {
			commands.append(.init(title: "\(L10n.playbackSpeed) \(next.displayTitle)", action: #selector(didSelectNextPlaybackSpeed),
			                      input: "]", modifierFlags: .command))
		}
		if viewModel.playbackSpeed != .one {
			commands.append(.init(title: "\(L10n.playbackSpeed) \(PlaybackSpeed.one.displayTitle)",
			                      action: #selector(didSelectNormalPlaybackSpeed), input: "\\", modifierFlags: .command))
		}
		commands.forEach { $0.wantsPriorityOverSystemBehavior = true }
		return commands
	}

	// MARK: init

	init(viewModel: VideoPlayerViewModel) {
		self.viewModel = viewModel
		self.vlcMediaPlayer = VLCMediaPlayer()

		super.init(nibName: nil, bundle: nil)

		viewModel.playerOverlayDelegate = self
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setupSubviews() {
		view.addSubview(videoContentView)
		view.addSubview(mainGestureView)

		// Setup BrightnessOverlayView
		systemControlOverlayLabel.alpha = 0
		systemControlOverlayLabel.translatesAutoresizingMaskIntoConstraints = false
		systemControlOverlayLabel.font = .systemFont(ofSize: 48)
		view.addSubview(systemControlOverlayLabel)
	}

	private func setupConstraints() {
		NSLayoutConstraint.activate([
			videoContentView.topAnchor.constraint(equalTo: view.topAnchor),
			videoContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
			videoContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
			videoContentView.rightAnchor.constraint(equalTo: view.rightAnchor),
		])
		NSLayoutConstraint.activate([
			mainGestureView.topAnchor.constraint(equalTo: videoContentView.topAnchor),
			mainGestureView.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
			mainGestureView.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
			mainGestureView.rightAnchor.constraint(equalTo: videoContentView.rightAnchor),
		])
		NSLayoutConstraint.activate([
			systemControlOverlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			systemControlOverlayLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
	}

	// MARK: viewWillDisappear

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		NotificationCenter.default.removeObserver(self)
	}

	// MARK: viewDidLoad

	override func viewDidLoad() {
		super.viewDidLoad()

		setupSubviews()
		setupConstraints()

		view.backgroundColor = .black
		view.accessibilityIgnoresInvertColors = true

		setupMediaPlayer(newViewModel: viewModel)

		refreshJumpBackwardOverlayView(with: viewModel.jumpBackwardLength)
		refreshJumpForwardOverlayView(with: viewModel.jumpForwardLength)

		let defaultNotificationCenter = NotificationCenter.default
		defaultNotificationCenter.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification,
		                                      object: nil)
		defaultNotificationCenter.addObserver(self, selector: #selector(appWillResignActive),
		                                      name: UIApplication.willResignActiveNotification, object: nil)
		defaultNotificationCenter.addObserver(self, selector: #selector(appWillResignActive),
		                                      name: UIApplication.didEnterBackgroundNotification, object: nil)
	}

	@objc
	private func appWillTerminate() {
		viewModel.sendStopReport()
	}

	@objc
	private func appWillResignActive() {
		hideChaptersOverlay()

		showOverlay()

		stopOverlayDismissTimer()

		vlcMediaPlayer.pause()

		viewModel.sendPauseReport(paused: true)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		startPlayback()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		if isScreenFilled {
			fillScreen(screenSize: size)
		}
		super.viewWillTransition(to: size, with: coordinator)
	}

	// MARK: VideoContentView

	private func makeVideoContentView() -> UIView {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		view.backgroundColor = .black

		return view
	}

	// MARK: MainGestureView

	private func makeMainGestureView() -> UIView {
		let view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false

		let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))

		let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didRightSwipe))
		rightSwipeGesture.direction = .right

		let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didLeftSwipe))
		leftSwipeGesture.direction = .left

		let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))

		let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))

		view.addGestureRecognizer(singleTapGesture)
		view.addGestureRecognizer(pinchGesture)

		if viewModel.jumpGesturesEnabled {
			view.addGestureRecognizer(rightSwipeGesture)
			view.addGestureRecognizer(leftSwipeGesture)
		}

		if viewModel.systemControlGesturesEnabled {
			view.addGestureRecognizer(panGesture)
		}

		return view
	}

	@objc
	private func didTap() {
		didGenerallyTap()
	}

	@objc
	private func didRightSwipe() {
		didSelectForward()
	}

	@objc
	private func didLeftSwipe() {
		didSelectBackward()
	}

	@objc
	private func didPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
		if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
			pinchScale = gestureRecognizer.scale
		} else {
			if pinchScale > 1, !isScreenFilled {
				isScreenFilled.toggle()
				fillScreen()
			} else if pinchScale < 1, isScreenFilled {
				isScreenFilled.toggle()
				shrinkScreen()
			}
		}
	}

	@objc
	private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
		switch gestureRecognizer.state {
		case .began:
			panBeganBrightness = UIScreen.main.brightness
			if let view = volumeView.subviews.first as? UISlider {
				panBeganVolumeValue = view.value
			}
			panBeganPoint = gestureRecognizer.location(in: mainGestureView)
		case .changed:
			let mainGestureViewHalfWidth = mainGestureView.frame.width * 0.5
			let mainGestureViewHalfHeight = mainGestureView.frame.height * 0.5

			let pos = gestureRecognizer.location(in: mainGestureView)
			let moveDelta = pos.y - panBeganPoint.y
			let changedValue = moveDelta / mainGestureViewHalfHeight

			if panBeganPoint.x < mainGestureViewHalfWidth {
				UIScreen.main.brightness = panBeganBrightness - changedValue
				flashBrightnessOverlay()
			} else if let view = volumeView.subviews.first as? UISlider {
				view.value = panBeganVolumeValue - Float(changedValue)
				flashVolumeOverlay()
			}
		default:
			hideSystemControlOverlay()
		}
	}

	// MARK: setupOverlayHostingController

	private func setupOverlayHostingController(viewModel: VideoPlayerViewModel) {
		// TODO: Look at injecting viewModel into the environment so it updates the current overlay
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

		let newOverlayView = VLCPlayerOverlayView(viewModel: viewModel)
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
			newOverlayHostingController.view.rightAnchor.constraint(equalTo: videoContentView.rightAnchor),
		])

		// UX fade-in
		UIView.animate(withDuration: 0.5) {
			newOverlayHostingController.view.alpha = 1
		}

		currentOverlayHostingController = newOverlayHostingController

		if let currentChapterOverlayHostingController = currentChapterOverlayHostingController {
			UIView.animate(withDuration: 0.5) {
				currentChapterOverlayHostingController.view.alpha = 0
			} completion: { _ in
				currentChapterOverlayHostingController.view.isHidden = true

				currentChapterOverlayHostingController.view.removeFromSuperview()
				currentChapterOverlayHostingController.removeFromParent()
			}
		}

		let newChapterOverlayView = VLCPlayerChapterOverlayView(viewModel: viewModel)
		let newChapterOverlayHostingController = UIHostingController(rootView: newChapterOverlayView)

		newChapterOverlayHostingController.view.translatesAutoresizingMaskIntoConstraints = false
		newChapterOverlayHostingController.view.backgroundColor = UIColor.clear

		newChapterOverlayHostingController.view.alpha = 0

		addChild(newChapterOverlayHostingController)
		view.addSubview(newChapterOverlayHostingController.view)
		newChapterOverlayHostingController.didMove(toParent: self)

		NSLayoutConstraint.activate([
			newChapterOverlayHostingController.view.topAnchor.constraint(equalTo: videoContentView.topAnchor),
			newChapterOverlayHostingController.view.bottomAnchor.constraint(equalTo: videoContentView.bottomAnchor),
			newChapterOverlayHostingController.view.leftAnchor.constraint(equalTo: videoContentView.leftAnchor),
			newChapterOverlayHostingController.view.rightAnchor.constraint(equalTo: videoContentView.rightAnchor),
		])

		currentChapterOverlayHostingController = newChapterOverlayHostingController

		// There is a weird behavior when after setting the new overlays that the navigation bar pops up, re-hide it
		navigationController?.isNavigationBarHidden = true
	}

	private func refreshJumpBackwardOverlayView(with jumpBackwardLength: VideoPlayerJumpLength) {
		if let currentJumpBackwardOverlayView = currentJumpBackwardOverlayView {
			currentJumpBackwardOverlayView.removeFromSuperview()
		}

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 48)
		let backwardSymbolImage = UIImage(systemName: jumpBackwardLength.backwardImageLabel, withConfiguration: symbolConfig)
		let newJumpBackwardImageView = UIImageView(image: backwardSymbolImage)

		newJumpBackwardImageView.translatesAutoresizingMaskIntoConstraints = false
		newJumpBackwardImageView.tintColor = .white

		newJumpBackwardImageView.alpha = 0

		view.addSubview(newJumpBackwardImageView)

		NSLayoutConstraint.activate([
			newJumpBackwardImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 150),
			newJumpBackwardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])

		currentJumpBackwardOverlayView = newJumpBackwardImageView
	}

	private func refreshJumpForwardOverlayView(with jumpForwardLength: VideoPlayerJumpLength) {
		if let currentJumpForwardOverlayView = currentJumpForwardOverlayView {
			currentJumpForwardOverlayView.removeFromSuperview()
		}

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 48)
		let forwardSymbolImage = UIImage(systemName: jumpForwardLength.forwardImageLabel, withConfiguration: symbolConfig)
		let newJumpForwardImageView = UIImageView(image: forwardSymbolImage)

		newJumpForwardImageView.translatesAutoresizingMaskIntoConstraints = false
		newJumpForwardImageView.tintColor = .white

		newJumpForwardImageView.alpha = 0

		view.addSubview(newJumpForwardImageView)

		NSLayoutConstraint.activate([
			newJumpForwardImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -150),
			newJumpForwardImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])

		currentJumpForwardOverlayView = newJumpForwardImageView
	}
}

// MARK: setupMediaPlayer

extension VLCPlayerViewController {
	/// Main function that handles setting up the media player with the current VideoPlayerViewModel
	/// and also takes the role of setting the 'viewModel' property with the given viewModel
	///
	/// Use case for this is setting new media within the same VLCPlayerViewController
	func setupMediaPlayer(newViewModel: VideoPlayerViewModel) {
		// remove old player

		if vlcMediaPlayer.media != nil {
			viewModelListeners.forEach { $0.cancel() }

			vlcMediaPlayer.stop()
			viewModel.sendStopReport()
			viewModel.playerOverlayDelegate = nil
		}

		vlcMediaPlayer = VLCMediaPlayer()

		// setup with new player and view model

		vlcMediaPlayer = VLCMediaPlayer()

		vlcMediaPlayer.delegate = self
		vlcMediaPlayer.drawable = videoContentView

		vlcMediaPlayer.setSubtitleSize(Defaults[.subtitleSize])

		stopOverlayDismissTimer()

		lastPlayerTicks = newViewModel.item.userData?.playbackPositionTicks ?? 0
		lastProgressReportTicks = newViewModel.item.userData?.playbackPositionTicks ?? 0

		let media: VLCMedia

		if let transcodedURL = newViewModel.transcodedStreamURL,
		   !Defaults[.Experimental.forceDirectPlay]
		{
			media = VLCMedia(url: transcodedURL)
		} else {
			media = VLCMedia(url: newViewModel.directStreamURL)
		}

		media.addOption("--prefetch-buffer-size=1048576")
		media.addOption("--network-caching=5000")

		vlcMediaPlayer.media = media

		setupOverlayHostingController(viewModel: newViewModel)
		setupViewModelListeners(viewModel: newViewModel)

		newViewModel.getAdjacentEpisodes()
		newViewModel.playerOverlayDelegate = self

		let startPercentage = newViewModel.item.userData?.playedPercentage ?? 0

		if startPercentage > 0 {
			if viewModel.resumeOffset {
				let runTimeTicks = viewModel.item.runTimeTicks ?? 0
				let videoDurationSeconds = Double(runTimeTicks / 10_000_000)
				var startSeconds = round((startPercentage / 100) * videoDurationSeconds)
				startSeconds = startSeconds.subtract(5, floor: 0)
				let newStartPercentage = startSeconds / videoDurationSeconds
				newViewModel.sliderPercentage = newStartPercentage
			} else {
				newViewModel.sliderPercentage = startPercentage / 100
			}
		}

		viewModel = newViewModel

		if viewModel.streamType == .direct {
			LogManager.shared.log.debug("Player set up with direct play stream for item: \(viewModel.item.id ?? "--")")
		} else if viewModel.streamType == .transcode && Defaults[.Experimental.forceDirectPlay] {
			LogManager.shared.log.debug("Player set up with forced direct stream for item: \(viewModel.item.id ?? "--")")
		} else {
			LogManager.shared.log.debug("Player set up with transcoded stream for item: \(viewModel.item.id ?? "--")")
		}
	}

	// MARK: startPlayback

	func startPlayback() {
		vlcMediaPlayer.play()

		// Setup external subtitles
		for externalSubtitle in viewModel.subtitleStreams.filter({ $0.deliveryMethod == .external }) {
			if let deliveryURL = externalSubtitle.externalURL(base: SessionManager.main.currentLogin.server.currentURI) {
				vlcMediaPlayer.addPlaybackSlave(deliveryURL, type: .subtitle, enforce: false)
			}
		}

		setMediaPlayerTimeAtCurrentSlider()

		viewModel.sendPlayReport()

		restartOverlayDismissTimer()
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

		viewModel.$jumpBackwardLength.sink { newJumpBackwardLength in
			self.refreshJumpBackwardOverlayView(with: newJumpBackwardLength)
		}.store(in: &viewModelListeners)

		viewModel.$jumpForwardLength.sink { newJumpForwardLength in
			self.refreshJumpForwardOverlayView(with: newJumpForwardLength)
		}.store(in: &viewModelListeners)
	}

	func setMediaPlayerTimeAtCurrentSlider() {
		// Necessary math as VLCMediaPlayer doesn't work well
		//     by just setting the position
		let runTimeTicks = viewModel.item.runTimeTicks ?? 0
		let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
		let videoDuration = Double(runTimeTicks / 10_000_000)
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
		guard !UIAccessibility.isVoiceOverRunning else { return }

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

// MARK: Show/Hide System Control

extension VLCPlayerViewController {
	private func flashBrightnessOverlay() {
		guard !displayingOverlay else { return }

		let imageAttachment = NSTextAttachment()
		imageAttachment.image = UIImage(systemName: "sun.max", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48))?
			.withTintColor(.white)

		let attributedString = NSMutableAttributedString()
		attributedString.append(.init(attachment: imageAttachment))
		attributedString.append(.init(string: " \(String(format: "%.0f", UIScreen.main.brightness * 100))%"))
		systemControlOverlayLabel.attributedText = attributedString
		systemControlOverlayLabel.layer.removeAllAnimations()

		UIView.animate(withDuration: 0.1) {
			self.systemControlOverlayLabel.alpha = 1
		}
	}

	private func flashVolumeOverlay() {
		guard !displayingOverlay,
		      let value = (volumeView.subviews.first as? UISlider)?.value else { return }

		let imageAttachment = NSTextAttachment()
		imageAttachment.image = UIImage(systemName: "speaker.wave.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48))?
			.withTintColor(.white)

		let attributedString = NSMutableAttributedString()
		attributedString.append(.init(attachment: imageAttachment))
		attributedString.append(.init(string: " \(String(format: "%.0f", value * 100))%"))
		systemControlOverlayLabel.attributedText = attributedString
		systemControlOverlayLabel.layer.removeAllAnimations()

		UIView.animate(withDuration: 0.1) {
			self.systemControlOverlayLabel.alpha = 1
		}
	}

	private func hideSystemControlOverlay() {
		UIView.animate(withDuration: 0.75) {
			self.systemControlOverlayLabel.alpha = 0
		}
	}
}

// MARK: Show/Hide Jump

extension VLCPlayerViewController {
	private func flashJumpBackwardOverlay() {
		guard !displayingOverlay, let currentJumpBackwardOverlayView = currentJumpBackwardOverlayView else { return }

		currentJumpBackwardOverlayView.layer.removeAllAnimations()

		UIView.animate(withDuration: 0.1) {
			currentJumpBackwardOverlayView.alpha = 1
		} completion: { _ in
			self.hideJumpBackwardOverlay()
		}
	}

	private func hideJumpBackwardOverlay() {
		guard let currentJumpBackwardOverlayView = currentJumpBackwardOverlayView else { return }

		UIView.animate(withDuration: 0.3) {
			currentJumpBackwardOverlayView.alpha = 0
		}
	}

	private func flashJumpFowardOverlay() {
		guard !displayingOverlay, let currentJumpForwardOverlayView = currentJumpForwardOverlayView else { return }

		currentJumpForwardOverlayView.layer.removeAllAnimations()

		UIView.animate(withDuration: 0.1) {
			currentJumpForwardOverlayView.alpha = 1
		} completion: { _ in
			self.hideJumpForwardOverlay()
		}
	}

	private func hideJumpForwardOverlay() {
		guard let currentJumpForwardOverlayView = currentJumpForwardOverlayView else { return }

		UIView.animate(withDuration: 0.3) {
			currentJumpForwardOverlayView.alpha = 0
		}
	}
}

// MARK: Hide/Show Chapters

extension VLCPlayerViewController {
	private func showChaptersOverlay() {
		guard let overlayHostingController = currentChapterOverlayHostingController else { return }

		guard overlayHostingController.view.alpha != 1 else { return }

		UIView.animate(withDuration: 0.2) {
			overlayHostingController.view.alpha = 1
		}
	}

	private func hideChaptersOverlay() {
		guard let overlayHostingController = currentChapterOverlayHostingController else { return }

		guard overlayHostingController.view.alpha != 0 else { return }

		UIView.animate(withDuration: 0.2) {
			overlayHostingController.view.alpha = 0
		}
	}
}

// MARK: OverlayTimer

extension VLCPlayerViewController {
	private func restartOverlayDismissTimer(interval: Double = 3) {
		overlayDismissTimer?.invalidate()
		overlayDismissTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(dismissTimerFired),
		                                           userInfo: nil, repeats: false)
	}

	@objc
	private func dismissTimerFired() {
		hideOverlay()
	}

	private func stopOverlayDismissTimer() {
		overlayDismissTimer?.invalidate()
	}
}

// MARK: VLCMediaPlayerDelegate

extension VLCPlayerViewController: VLCMediaPlayerDelegate {
	// MARK: mediaPlayerStateChanged

	func mediaPlayerStateChanged(_ aNotification: Notification!) {
		// Don't show buffering if paused, usually here while scrubbing
		if vlcMediaPlayer.state == .buffering, viewModel.playerState == .paused {
			return
		}

		viewModel.playerState = vlcMediaPlayer.state

		if vlcMediaPlayer.state == VLCMediaPlayerState.ended {
			if viewModel.autoplayEnabled, viewModel.nextItemVideoPlayerViewModel != nil {
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

		// Have to manually set playing because VLCMediaPlayer doesn't
		// properly set it itself
		if abs(currentPlayerTicks - lastPlayerTicks) >= 10000 {
			viewModel.playerState = VLCMediaPlayerState.playing
		}

		// If needing to fix subtitle streams during playback
		if vlcMediaPlayer.currentVideoSubTitleIndex != viewModel.selectedSubtitleStreamIndex,
		   viewModel.subtitlesEnabled
		{
			didSelectSubtitleStream(index: viewModel.selectedSubtitleStreamIndex)
		}

		// If needing to fix audio stream during playback
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

// MARK: PlayerOverlayDelegate and more

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

	@objc
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

	@objc
	func didSelectBackward() {
		flashJumpBackwardOverlay()

		vlcMediaPlayer.jumpBackward(viewModel.jumpBackwardLength.rawValue)

		if displayingOverlay {
			restartOverlayDismissTimer()
		}

		viewModel.sendProgressReport()

		lastProgressReportTicks = currentPlayerTicks
	}

	@objc
	func didSelectForward() {
		flashJumpFowardOverlay()

		vlcMediaPlayer.jumpForward(viewModel.jumpForwardLength.rawValue)

		if displayingOverlay {
			restartOverlayDismissTimer()
		}

		viewModel.sendProgressReport()

		lastProgressReportTicks = currentPlayerTicks
	}

	@objc
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

	@objc
	func didSelectPlayPreviousItem() {
		if let previousItemVideoPlayerViewModel = viewModel.previousItemVideoPlayerViewModel {
			setupMediaPlayer(newViewModel: previousItemVideoPlayerViewModel)
			startPlayback()
		}
	}

	@objc
	func didSelectPlayNextItem() {
		if let nextItemVideoPlayerViewModel = viewModel.nextItemVideoPlayerViewModel {
			setupMediaPlayer(newViewModel: nextItemVideoPlayerViewModel)
			startPlayback()
		}
	}

	@objc
	func didSelectPreviousPlaybackSpeed() {
		if let previousPlaybackSpeed = viewModel.playbackSpeed.previous {
			viewModel.playbackSpeed = previousPlaybackSpeed
		}
	}

	@objc
	func didSelectNextPlaybackSpeed() {
		if let nextPlaybackSpeed = viewModel.playbackSpeed.next {
			viewModel.playbackSpeed = nextPlaybackSpeed
		}
	}

	@objc
	func didSelectNormalPlaybackSpeed() {
		viewModel.playbackSpeed = .one
	}

	func didSelectChapters() {
		if displayingChapterOverlay {
			hideChaptersOverlay()
		} else {
			hideOverlay()
			showChaptersOverlay()
		}
	}

	func didSelectChapter(_ chapter: ChapterInfo) {
		let videoPosition = Double(vlcMediaPlayer.time.intValue / 1000)
		let chapterSeconds = Double((chapter.startPositionTicks ?? 0) / 10_000_000)
		let newPositionOffset = chapterSeconds - videoPosition

		if newPositionOffset > 0 {
			vlcMediaPlayer.jumpForward(Int32(newPositionOffset))
		} else {
			vlcMediaPlayer.jumpBackward(Int32(abs(newPositionOffset)))
		}

		viewModel.sendProgressReport()
	}

	func didSelectScreenFill() {
		isScreenFilled.toggle()

		if isScreenFilled {
			fillScreen()
		} else {
			shrinkScreen()
		}
	}

	private func fillScreen(screenSize: CGSize = UIScreen.main.bounds.size) {
		let videoSize = vlcMediaPlayer.videoSize
		let fillSize = CGSize.aspectFill(aspectRatio: videoSize, minimumSize: screenSize)

		let scale: CGFloat

		if fillSize.height > screenSize.height {
			scale = fillSize.height / screenSize.height
		} else {
			scale = fillSize.width / screenSize.width
		}

		UIView.animate(withDuration: 0.2) {
			self.videoContentView.transform = CGAffineTransform(scaleX: scale, y: scale)
		}
	}

	private func shrinkScreen() {
		UIView.animate(withDuration: 0.2) {
			self.videoContentView.transform = .identity
		}
	}

	func getScreenFilled() -> Bool {
		isScreenFilled
	}

	func isVideoAspectRatioGreater() -> Bool {
		let screenSize = UIScreen.main.bounds.size
		let videoSize = vlcMediaPlayer.videoSize

		let screenAspectRatio = screenSize.width / screenSize.height
		let videoAspectRatio = videoSize.width / videoSize.height

		return videoAspectRatio > screenAspectRatio
	}
}
