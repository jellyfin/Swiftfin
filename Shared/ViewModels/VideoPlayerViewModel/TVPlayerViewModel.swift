//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Algorithms
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

final class TVPlayerViewModel: ViewModel {

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
    var subtitlesEnabled: Bool

    @Published
    var selectedAudioStreamIndex: Int
    @Published
    var selectedSubtitleStreamIndex: Int

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
    var mediaItems: [BaseItemDto.ItemDetail]

    // MARK: ShouldShowItems

    let shouldShowJumpButtonsInOverlayMenu: Bool

    // MARK: General

    private(set) var item: BaseItemDto
    let title: String
    let subtitle: String?
    let directStreamURL: URL
    let transcodedStreamURL: URL?
    let localFileURL: URL?
    let hlsStreamURL: URL
    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let chapters: [ChapterInfo]
    let overlayType: OverlayType
    let jumpGesturesEnabled: Bool
    let resumeOffset: Bool
    let streamType: ServerStreamType
    let container: String
    let filename: String?
    let versionName: String?

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
        let runTimeTicks = item.runTimeTicks ?? 0
        let videoDuration = Double(runTimeTicks / 10_000_000)
        return round(sliderPercentage * videoDuration)
    }

    var currentSecondTicks: Int64 {
        Int64(currentSeconds) * 10_000_000
    }

    func setSeconds(_ seconds: Int64) {
        let videoDuration = item.runTimeTicks!
        let percentage = Double(seconds * 10_000_000) / Double(videoDuration)

        sliderPercentage = percentage
    }

    // MARK: Helpers

    var currentAudioStream: MediaStream? {
        audioStreams.first(where: { $0.index == selectedAudioStreamIndex })
    }

    var currentSubtitleStream: MediaStream? {
        subtitleStreams.first(where: { $0.index == selectedSubtitleStreamIndex })
    }

    var currentChapter: ChapterInfo? {

        let chapterPairs = chapters.adjacentPairs().map { ($0, $1) }
        let chapterRanges = chapterPairs.map { ($0.startPositionTicks ?? 0, ($1.startPositionTicks ?? 1) - 1) }

        for chapterRangeIndex in 0 ..< chapterRanges.count {
            if chapterRanges[chapterRangeIndex].0 <= currentSecondTicks &&
                currentSecondTicks < chapterRanges[chapterRangeIndex].1
            {
                return chapterPairs[chapterRangeIndex].0
            }
        }

        return nil
    }

    // Necessary PassthroughSubject to capture manual scrubbing from sliders
    let sliderScrubbingSubject = PassthroughSubject<TVPlayerViewModel, Never>()

    // During scrubbing, many progress reports were spammed
    // Send only the current report after a delay
    private var progressReportTimer: Timer?
    private var lastProgressReport: PlaybackProgressInfo?

    // MARK: init

    init(item: BaseItemDto,
         title: String,
         subtitle: String?,
         directStreamURL: URL,
         transcodedStreamURL: URL?,
         hlsStreamURL: URL,
         streamType: ServerStreamType,
         response: PlaybackInfoResponse,
         audioStreams: [MediaStream],
         subtitleStreams: [MediaStream],
         chapters: [ChapterInfo],
         selectedAudioStreamIndex: Int,
         selectedSubtitleStreamIndex: Int,
         subtitlesEnabled: Bool,
         overlayType: OverlayType,
         container: String,
         filename: String?,
         versionName: String?)
    {
        self.item = item
        self.title = title
        self.subtitle = subtitle
        self.directStreamURL = directStreamURL
        self.transcodedStreamURL = transcodedStreamURL
        self.hlsStreamURL = hlsStreamURL
        self.streamType = streamType
        self.response = response
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
        self.chapters = chapters
        self.selectedAudioStreamIndex = selectedAudioStreamIndex
        self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
        self.subtitlesEnabled = subtitlesEnabled
        self.overlayType = overlayType
        self.container = container
        self.filename = filename
        self.versionName = versionName

        self.jumpBackwardLength = Defaults[.videoPlayerJumpBackward]
        self.jumpForwardLength = Defaults[.videoPlayerJumpForward]
        self.jumpGesturesEnabled = Defaults[.jumpGesturesEnabled]
        self.shouldShowJumpButtonsInOverlayMenu = Defaults[.shouldShowJumpButtonsInOverlayMenu]

        self.resumeOffset = Defaults[.resumeOffset]

        self.syncSubtitleStateWithAdjacent = Defaults[.Experimental.syncSubtitleStateWithAdjacent]

        self.confirmClose = Defaults[.confirmClose]

        self.mediaItems = item.createMediaItems()
        
        var potentialLocalFileURL: URL? = nil
        
        if let filename = filename {
            if DownloadManager.main.hasLocalFile(for: item, fileName: filename) {
                potentialLocalFileURL = DownloadManager.main.localFileURL(for: item, fileName: filename)
            }
        }
        
        self.localFileURL = potentialLocalFileURL

        super.init()

        self.sliderPercentage = (item.userData?.playedPercentage ?? 0) / 100
    }

    private func sliderPercentageChanged(newValue: Double) {
        let runTimeTicks = item.runTimeTicks ?? 0
        let videoDuration = Double(runTimeTicks / 10_000_000)
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

// MARK: Progress Report Timer

extension TVPlayerViewModel {

    private func sendNewProgressReportWithTimer() {
        self.progressReportTimer?.invalidate()
        self.progressReportTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(_sendProgressReport),
                                                        userInfo: nil, repeats: false)
    }
}

// MARK: Updates

extension TVPlayerViewModel {

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
                Notifications[.didSendStopReport].post(object: self.item.id)
            }
            .store(in: &cancellables)
    }
}

// MARK: Equatable

extension TVPlayerViewModel: Equatable {

    static func == (lhs: TVPlayerViewModel, rhs: TVPlayerViewModel) -> Bool {
        lhs.item.id == rhs.item.id &&
            lhs.item.userData?.playbackPositionTicks == rhs.item.userData?.playbackPositionTicks
    }
}

// MARK: Hashable

extension TVPlayerViewModel: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
        hasher.combine(directStreamURL)
        hasher.combine(filename)
        hasher.combine(versionName)
    }
}
