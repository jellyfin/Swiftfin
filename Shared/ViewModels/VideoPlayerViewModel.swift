//
//  VideoPlayerViewModel.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/12/21.
//

import Combine
import Foundation
import JellyfinAPI
import UIKit

#if os(tvOS)
import TVVLCKit
#else
import MobileVLCKit
#endif

final class VideoPlayerViewModel: ViewModel {
    
    // Manually kept state because VLCKit doesn't properly set "played"
    // on the VLCMediaPlayer object
    @Published var playerState: VLCMediaPlayerState
    @Published var shouldShowGoogleCast: Bool
    @Published var shouldShowAirplay: Bool
    @Published var subtitlesEnabled: Bool {
        didSet {
            if subtitlesEnabled != oldValue {
                previousItemVideoPlayerViewModel?.matchSubtitlesEnabled(with: self)
                nextItemVideoPlayerViewModel?.matchSubtitlesEnabled(with: self)
            }
        }
    }
    @Published var leftLabelText: String = "--:--"
    @Published var rightLabelText: String = "--:--"
    @Published var playbackSpeed: PlaybackSpeed = .one
    @Published var screenFilled: Bool = false
    @Published var sliderPercentage: Double {
        willSet {
            sliderScrubbingSubject.send(self)
            sliderPercentageChanged(newValue: newValue)
        }
    }
    @Published var sliderIsScrubbing: Bool = false
    @Published var selectedAudioStreamIndex: Int {
        didSet {
            previousItemVideoPlayerViewModel?.matchAudioStream(with: self)
            nextItemVideoPlayerViewModel?.matchAudioStream(with: self)
        }
    }
    @Published var selectedSubtitleStreamIndex: Int {
        didSet {
            previousItemVideoPlayerViewModel?.matchSubtitleStream(with:  self)
            nextItemVideoPlayerViewModel?.matchSubtitleStream(with: self)
        }
    }
    @Published var showAdjacentItems: Bool
    @Published var previousItemVideoPlayerViewModel: VideoPlayerViewModel?
    @Published var nextItemVideoPlayerViewModel: VideoPlayerViewModel?
    
    let item: BaseItemDto
    let title: String
    let subtitle: String?
    let streamURL: URL
    let hlsURL: URL
    // Full response kept for convenience
    let response: PlaybackInfoResponse
    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let defaultAudioStreamIndex: Int
    let defaultSubtitleStreamIndex: Int
    
    var playerOverlayDelegate: PlayerOverlayDelegate?
    
    // Ticks of the time the media has begun
    var startTimeTicks: Int64?
    
    var currentSeconds: Double {
        let videoDuration = Double(item.runTimeTicks! / 10_000_000)
        return round(sliderPercentage * videoDuration)
    }
    
    var currentSecondTicks: Int64 {
        return Int64(currentSeconds) * 10_000_000
    }
    
    // Necessary PassthroughSubject to capture manual scrubbing from sliders
    let sliderScrubbingSubject = PassthroughSubject<VideoPlayerViewModel, Never>()
    
    // MARK: init
    
    init(item: BaseItemDto,
         title: String,
         subtitle: String?,
         streamURL: URL,
         hlsURL: URL,
         response: PlaybackInfoResponse,
         audioStreams: [MediaStream],
         subtitleStreams: [MediaStream],
         defaultAudioStreamIndex: Int,
         defaultSubtitleStreamIndex: Int,
         playerState: VLCMediaPlayerState,
         shouldShowGoogleCast: Bool,
         shouldShowAirplay: Bool,
         subtitlesEnabled: Bool,
         sliderPercentage: Double,
         selectedAudioStreamIndex: Int,
         selectedSubtitleStreamIndex: Int,
         showAdjacentItems: Bool) {
        self.item = item
        self.title = title
        self.subtitle = subtitle
        self.streamURL = streamURL
        self.hlsURL = hlsURL
        self.response = response
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
        self.defaultAudioStreamIndex = defaultAudioStreamIndex
        self.defaultSubtitleStreamIndex = defaultSubtitleStreamIndex
        self.playerState = playerState
        self.shouldShowGoogleCast = shouldShowGoogleCast
        self.shouldShowAirplay = shouldShowAirplay
        self.subtitlesEnabled = subtitlesEnabled
        self.sliderPercentage = sliderPercentage
        self.selectedAudioStreamIndex = selectedAudioStreamIndex
        self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
        self.showAdjacentItems = showAdjacentItems
        
        super.init()
        
        self.sliderPercentageChanged(newValue: (item.userData?.playedPercentage ?? 0) / 100)
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
                print(completion)
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
    
    private func matchSubtitleStream(with masterViewModel: VideoPlayerViewModel) {
        if !masterViewModel.subtitlesEnabled {
            matchSubtitlesEnabled(with: masterViewModel)
        }
        
        guard let masterSubtitleStream = masterViewModel.subtitleStreams.first(where: { $0.index == masterViewModel.selectedSubtitleStreamIndex }),
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
        return lhs.displayTitle == rhs.displayTitle && lhs.language == rhs.language
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
                                          playlistItemId: "playlistItem0"
        )
        
        PlaystateAPI.reportPlaybackStart(playbackStartInfo: startInfo)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { _ in
                print("Playback start report sent!")
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
                                          playlistItemId: "playlistItem0"
        )
        
        PlaystateAPI.reportPlaybackStart(playbackStartInfo: pauseInfo)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { _ in
                print("Pause report sent!")
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
        
        PlaystateAPI.reportPlaybackProgress(playbackProgressInfo: progressInfo)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { _ in
                print("Playback progress sent!")
            }
            .store(in: &cancellables)
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
                print("Playback stop report sent!")
            }
            .store(in: &cancellables)
    }
}
