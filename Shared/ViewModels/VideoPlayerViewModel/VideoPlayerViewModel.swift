//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import UIKit

#if os(tvOS)
	import TVVLCKit
#else
	import MobileVLCKit
#endif

final class VideoPlayerViewModel: ViewModel {

	// MARK: Published

	// Manually kept state because VLCKit doesn't properly set "played"
	// on the VLCMediaPlayer object
	@Published
	var playerState: VLCMediaPlayerState = .buffering
	@Published
	var leftLabelText: String = "--:--"
	@Published
	var rightLabelText: String = "--:--"
	@Published
	var playbackSpeed: PlaybackSpeed = .one
	@Published
	var subtitlesEnabled: Bool {
		didSet {
			if syncSubtitleStateWithAdjacent {
				previousItemVideoPlayerViewModel?.matchSubtitlesEnabled(with: self)
				nextItemVideoPlayerViewModel?.matchSubtitlesEnabled(with: self)
			}
		}
	}

	@Published
	var selectedAudioStreamIndex: Int
	@Published
	var selectedSubtitleStreamIndex: Int {
		didSet {
			if syncSubtitleStateWithAdjacent {
				previousItemVideoPlayerViewModel?.matchSubtitleStream(with: self)
				nextItemVideoPlayerViewModel?.matchSubtitleStream(with: self)
			}
		}
	}

	@Published
	var previousItemVideoPlayerViewModel: VideoPlayerViewModel?
	@Published
	var nextItemVideoPlayerViewModel: VideoPlayerViewModel?
	@Published
	var jumpBackwardLength: VideoPlayerJumpLength {
		willSet {
			Defaults[.videoPlayerJumpBackward] = newValue
		}
	}

	@Published
	var jumpForwardLength: VideoPlayerJumpLength {
		willSet {
			Defaults[.videoPlayerJumpForward] = newValue
		}
	}

	@Published
	var sliderIsScrubbing: Bool = false
	@Published
	var sliderPercentage: Double = 0 {
		willSet {
			sliderScrubbingSubject.send(self)
			sliderPercentageChanged(newValue: newValue)
		}
	}

	@Published
	var autoplayEnabled: Bool {
		willSet {
			previousItemVideoPlayerViewModel?.autoplayEnabled = newValue
			nextItemVideoPlayerViewModel?.autoplayEnabled = newValue
			Defaults[.autoplayEnabled] = newValue
		}
	}

	// MARK: ShouldShowItems

	let shouldShowPlayPreviousItem: Bool
	let shouldShowPlayNextItem: Bool
	let shouldShowAutoPlay: Bool
	let shouldShowJumpButtonsInOverlayMenu: Bool

	// MARK: General

	let item: BaseItemDto
	let title: String
	let subtitle: String?
	let streamURL: URL
	let audioStreams: [MediaStream]
	let subtitleStreams: [MediaStream]
	let overlayType: OverlayType
	let jumpGesturesEnabled: Bool
	let resumeOffset: Bool
	let streamType: ServerStreamType

	// MARK: Experimental

	let syncSubtitleStateWithAdjacent: Bool

	// MARK: tvOS

	let confirmClose: Bool

	// Full response kept for convenience
	let response: PlaybackInfoResponse

	var playerOverlayDelegate: PlayerOverlayDelegate?

	// Ticks of the time the media began playing
	private var startTimeTicks: Int64 = 0

	// MARK: Current Time

	var currentSeconds: Double {
		let videoDuration = Double(item.runTimeTicks! / 10_000_000)
		return round(sliderPercentage * videoDuration)
	}

	var currentSecondTicks: Int64 {
		Int64(currentSeconds) * 10_000_000
	}

	// MARK: Helpers

	var currentAudioStream: MediaStream? {
		audioStreams.first(where: { $0.index == selectedAudioStreamIndex })
	}

	var currentSubtitleStream: MediaStream? {
		subtitleStreams.first(where: { $0.index == selectedSubtitleStreamIndex })
	}

	// Necessary PassthroughSubject to capture manual scrubbing from sliders
	let sliderScrubbingSubject = PassthroughSubject<VideoPlayerViewModel, Never>()

	// During scrubbing, many progress reports were spammed
	// Send only the current report after a delay
	private var progressReportTimer: Timer?
	private var lastProgressReport: PlaybackProgressInfo?

	// MARK: init

	init(item: BaseItemDto,
	     title: String,
	     subtitle: String?,
	     streamURL: URL,
	     streamType: ServerStreamType,
	     response: PlaybackInfoResponse,
	     audioStreams: [MediaStream],
	     subtitleStreams: [MediaStream],
	     selectedAudioStreamIndex: Int,
	     selectedSubtitleStreamIndex: Int,
	     subtitlesEnabled: Bool,
	     autoplayEnabled: Bool,
	     overlayType: OverlayType,
	     shouldShowPlayPreviousItem: Bool,
	     shouldShowPlayNextItem: Bool,
	     shouldShowAutoPlay: Bool)
	{
		self.item = item
		self.title = title
		self.subtitle = subtitle
		self.streamURL = streamURL
		self.streamType = streamType
		self.response = response
		self.audioStreams = audioStreams
		self.subtitleStreams = subtitleStreams
		self.selectedAudioStreamIndex = selectedAudioStreamIndex
		self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
		self.subtitlesEnabled = subtitlesEnabled
		self.autoplayEnabled = autoplayEnabled
		self.overlayType = overlayType
		self.shouldShowPlayPreviousItem = shouldShowPlayPreviousItem
		self.shouldShowPlayNextItem = shouldShowPlayNextItem
		self.shouldShowAutoPlay = shouldShowAutoPlay

		self.jumpBackwardLength = Defaults[.videoPlayerJumpBackward]
		self.jumpForwardLength = Defaults[.videoPlayerJumpForward]
		self.jumpGesturesEnabled = Defaults[.jumpGesturesEnabled]
		self.shouldShowJumpButtonsInOverlayMenu = Defaults[.shouldShowJumpButtonsInOverlayMenu]

		self.resumeOffset = Defaults[.resumeOffset]

		self.syncSubtitleStateWithAdjacent = Defaults[.Experimental.syncSubtitleStateWithAdjacent]

		self.confirmClose = Defaults[.confirmClose]

		super.init()

		self.sliderPercentage = (item.userData?.playedPercentage ?? 0) / 100
	}

	private func sliderPercentageChanged(newValue: Double) {
		let videoDuration = Double(item.runTimeTicks! / 10_000_000)
		let secondsScrubbedRemaining = videoDuration - currentSeconds

		leftLabelText = calculateTimeText(from: currentSeconds)
		rightLabelText = calculateTimeText(from: secondsScrubbedRemaining)
	}

	private func calculateTimeText(from duration: Double) -> String {
		let hours = floor(duration / 3600)
		let minutes = duration.truncatingRemainder(dividingBy: 3600) / 60
		let seconds = duration.truncatingRemainder(dividingBy: 3600).truncatingRemainder(dividingBy: 60)

		let timeText: String

		if hours != 0 {
			timeText =
				"\(Int(hours)):\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
		} else {
			timeText =
				"\(String(Int(floor(minutes))).leftPad(toWidth: 2, withString: "0")):\(String(Int(floor(seconds))).leftPad(toWidth: 2, withString: "0"))"
		}

		return timeText
	}
}

// MARK: Adjacent Items

extension VideoPlayerViewModel {

	func getAdjacentEpisodes() {
		guard let seriesID = item.seriesId, item.itemType == .episode else { return }

		TvShowsAPI.getEpisodes(seriesId: seriesID,
		                       userId: SessionManager.main.currentLogin.user.id,
		                       adjacentTo: item.id,
		                       limit: 3)
			.sink(receiveCompletion: { completion in
				self.handleAPIRequestError(completion: completion)
			}, receiveValue: { response in

				// 4 possible states:
				//  1 - only current episode
				//  2 - two episodes with next episode
				//  3 - two episodes with previous episode
				//  4 - three episodes with current in middle

				// State 1
				guard let items = response.items, items.count > 1 else { return }

				if items.count == 2 {
					if items[0].id == self.item.id {
						// State 2
						let nextItem = items[1]

						nextItem.createVideoPlayerViewModel()
							.sink { completion in
								self.handleAPIRequestError(completion: completion)
							} receiveValue: { videoPlayerViewModel in
								videoPlayerViewModel.matchSubtitleStream(with: self)
								videoPlayerViewModel.matchAudioStream(with: self)

								self.nextItemVideoPlayerViewModel = videoPlayerViewModel
							}
							.store(in: &self.cancellables)
					} else {
						// State 3
						let previousItem = items[0]

						previousItem.createVideoPlayerViewModel()
							.sink { completion in
								self.handleAPIRequestError(completion: completion)
							} receiveValue: { videoPlayerViewModel in
								videoPlayerViewModel.matchSubtitleStream(with: self)
								videoPlayerViewModel.matchAudioStream(with: self)

								self.previousItemVideoPlayerViewModel = videoPlayerViewModel
							}
							.store(in: &self.cancellables)
					}
				} else {
					// State 4

					let previousItem = items[0]
					let nextItem = items[2]

					previousItem.createVideoPlayerViewModel()
						.sink { completion in
							self.handleAPIRequestError(completion: completion)
						} receiveValue: { videoPlayerViewModel in
							videoPlayerViewModel.matchSubtitleStream(with: self)
							videoPlayerViewModel.matchAudioStream(with: self)

							self.previousItemVideoPlayerViewModel = videoPlayerViewModel
						}
						.store(in: &self.cancellables)

					nextItem.createVideoPlayerViewModel()
						.sink { completion in
							self.handleAPIRequestError(completion: completion)
						} receiveValue: { videoPlayerViewModel in
							videoPlayerViewModel.matchSubtitleStream(with: self)
							videoPlayerViewModel.matchAudioStream(with: self)

							self.nextItemVideoPlayerViewModel = videoPlayerViewModel
						}
						.store(in: &self.cancellables)
				}
			})
			.store(in: &cancellables)
	}

	// Potential for experimental feature of syncing subtitle states among adjacent episodes
	// when using previous & next item buttons and auto-play

	private func matchSubtitleStream(with masterViewModel: VideoPlayerViewModel) {
		if !masterViewModel.subtitlesEnabled {
			matchSubtitlesEnabled(with: masterViewModel)
		}

		guard let masterSubtitleStream = masterViewModel.subtitleStreams
			.first(where: { $0.index == masterViewModel.selectedSubtitleStreamIndex }),
			let matchingSubtitleStream = self.subtitleStreams.first(where: { mediaStreamAboutEqual($0, masterSubtitleStream) }),
			let matchingSubtitleStreamIndex = matchingSubtitleStream.index else { return }

		self.selectedSubtitleStreamIndex = matchingSubtitleStreamIndex
	}

	private func matchAudioStream(with masterViewModel: VideoPlayerViewModel) {
		guard let currentAudioStream = masterViewModel.audioStreams.first(where: { $0.index == masterViewModel.selectedAudioStreamIndex }),
		      let matchingAudioStream = self.audioStreams.first(where: { mediaStreamAboutEqual($0, currentAudioStream) }) else { return }

		self.selectedAudioStreamIndex = matchingAudioStream.index ?? -1
	}

	private func matchSubtitlesEnabled(with masterViewModel: VideoPlayerViewModel) {
		self.subtitlesEnabled = masterViewModel.subtitlesEnabled
	}

	private func mediaStreamAboutEqual(_ lhs: MediaStream, _ rhs: MediaStream) -> Bool {
		lhs.displayTitle == rhs.displayTitle && lhs.language == rhs.language
	}
}

// MARK: Progress Report Timer

extension VideoPlayerViewModel {

	private func sendNewProgressReportWithTimer() {
		self.progressReportTimer?.invalidate()
		self.progressReportTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(_sendProgressReport),
		                                                userInfo: nil, repeats: false)
	}
}

// MARK: Updates

extension VideoPlayerViewModel {

	// MARK: sendPlayReport

	func sendPlayReport() {

		self.startTimeTicks = Int64(Date().timeIntervalSince1970) * 10_000_000

		let subtitleStreamIndex = subtitlesEnabled ? selectedSubtitleStreamIndex : nil

		let startInfo = PlaybackStartInfo(canSeek: true,
		                                  item: item,
		                                  itemId: item.id,
		                                  sessionId: response.playSessionId,
		                                  mediaSourceId: item.id,
		                                  audioStreamIndex: selectedAudioStreamIndex,
		                                  subtitleStreamIndex: subtitleStreamIndex,
		                                  isPaused: false,
		                                  isMuted: false,
		                                  positionTicks: item.userData?.playbackPositionTicks,
		                                  playbackStartTimeTicks: startTimeTicks,
		                                  volumeLevel: 100,
		                                  brightness: 100,
		                                  aspectRatio: nil,
		                                  playMethod: .directPlay,
		                                  liveStreamId: nil,
		                                  playSessionId: response.playSessionId,
		                                  repeatMode: .repeatNone,
		                                  nowPlayingQueue: nil,
		                                  playlistItemId: "playlistItem0")

		PlaystateAPI.reportPlaybackStart(playbackStartInfo: startInfo)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { _ in
				LogManager.shared.log.debug("Start report sent for item: \(self.item.id ?? "No ID")")
			}
			.store(in: &cancellables)
	}

	// MARK: sendPauseReport

	func sendPauseReport(paused: Bool) {

		let subtitleStreamIndex = subtitlesEnabled ? selectedSubtitleStreamIndex : nil

		let pauseInfo = PlaybackStartInfo(canSeek: true,
		                                  item: item,
		                                  itemId: item.id,
		                                  sessionId: response.playSessionId,
		                                  mediaSourceId: item.id,
		                                  audioStreamIndex: selectedAudioStreamIndex,
		                                  subtitleStreamIndex: subtitleStreamIndex,
		                                  isPaused: paused,
		                                  isMuted: false,
		                                  positionTicks: currentSecondTicks,
		                                  playbackStartTimeTicks: startTimeTicks,
		                                  volumeLevel: 100,
		                                  brightness: 100,
		                                  aspectRatio: nil,
		                                  playMethod: .directPlay,
		                                  liveStreamId: nil,
		                                  playSessionId: response.playSessionId,
		                                  repeatMode: .repeatNone,
		                                  nowPlayingQueue: nil,
		                                  playlistItemId: "playlistItem0")

		PlaystateAPI.reportPlaybackStart(playbackStartInfo: pauseInfo)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { _ in
				LogManager.shared.log.debug("Pause report sent for item: \(self.item.id ?? "No ID")")
			}
			.store(in: &cancellables)
	}

	// MARK: sendProgressReport

	func sendProgressReport() {

		let subtitleStreamIndex = subtitlesEnabled ? selectedSubtitleStreamIndex : nil

		let progressInfo = PlaybackProgressInfo(canSeek: true,
		                                        item: item,
		                                        itemId: item.id,
		                                        sessionId: response.playSessionId,
		                                        mediaSourceId: item.id,
		                                        audioStreamIndex: selectedAudioStreamIndex,
		                                        subtitleStreamIndex: subtitleStreamIndex,
		                                        isPaused: false,
		                                        isMuted: false,
		                                        positionTicks: currentSecondTicks,
		                                        playbackStartTimeTicks: startTimeTicks,
		                                        volumeLevel: nil,
		                                        brightness: nil,
		                                        aspectRatio: nil,
		                                        playMethod: .directPlay,
		                                        liveStreamId: nil,
		                                        playSessionId: response.playSessionId,
		                                        repeatMode: .repeatNone,
		                                        nowPlayingQueue: nil,
		                                        playlistItemId: "playlistItem0")

		self.lastProgressReport = progressInfo

		self.sendNewProgressReportWithTimer()
	}

	@objc
	private func _sendProgressReport() {
		guard let lastProgressReport = lastProgressReport else { return }

		PlaystateAPI.reportPlaybackProgress(playbackProgressInfo: lastProgressReport)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { _ in
				LogManager.shared.log.debug("Playback progress sent for item: \(self.item.id ?? "No ID")")
			}
			.store(in: &cancellables)

		self.lastProgressReport = nil
	}

	// MARK: sendStopReport

	func sendStopReport() {

		let stopInfo = PlaybackStopInfo(item: item,
		                                itemId: item.id,
		                                sessionId: response.playSessionId,
		                                mediaSourceId: item.id,
		                                positionTicks: currentSecondTicks,
		                                liveStreamId: nil,
		                                playSessionId: response.playSessionId,
		                                failed: nil,
		                                nextMediaType: nil,
		                                playlistItemId: "playlistItem0",
		                                nowPlayingQueue: nil)

		PlaystateAPI.reportPlaybackStopped(playbackStopInfo: stopInfo)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { _ in
				LogManager.shared.log.debug("Stop report sent for item: \(self.item.id ?? "No ID")")
				SwiftfinNotificationCenter.main.post(name: SwiftfinNotificationCenter.Keys.didSendStopReport,
				                                     object: self.item.id)
			}
			.store(in: &cancellables)
	}
}

// MARK: Embedded/Normal Subtitle Streams

extension VideoPlayerViewModel {

	func createEmbeddedSubtitleStream(with subtitleStream: MediaStream) -> URL {

		guard let baseURL = URLComponents(url: streamURL, resolvingAgainstBaseURL: false) else { fatalError() }
		guard let queryItems = baseURL.queryItems else { fatalError() }

		var newURL = baseURL
		var newQueryItems = queryItems

		newQueryItems.removeAll(where: { $0.name == "SubtitleStreamIndex" })
		newQueryItems.removeAll(where: { $0.name == "SubtitleMethod" })

		newURL.addQueryItem(name: "SubtitleMethod", value: "Encode")
		newURL.addQueryItem(name: "SubtitleStreamIndex", value: "\(subtitleStream.index ?? -1)")

		return newURL.url!
	}
}

// MARK: Equatable

extension VideoPlayerViewModel: Equatable {

	static func == (lhs: VideoPlayerViewModel, rhs: VideoPlayerViewModel) -> Bool {
		lhs.item.id == rhs.item.id &&
			lhs.item.userData?.playbackPositionTicks == rhs.item.userData?.playbackPositionTicks
	}
}
