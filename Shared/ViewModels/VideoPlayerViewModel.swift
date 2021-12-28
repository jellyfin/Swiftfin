//
//  VideoPlayerViewModel.swift
//  JellyfinVideoPlayerDev
//
//  Created by Ethan Pippin on 11/12/21.
//

import Combine
import Foundation
import JellyfinAPI
#if os(tvOS)
import TVVLCKit
#else
import MobileVLCKit
#endif
import Stinsen
import UIKit

final class VideoPlayerViewModel: ObservableObject {
    
    // Manually kept state because VLCKit doesn't properly set "played"
    // on the VLCMediaPlayer object
    @Published var playerState: VLCMediaPlayerState
    @Published var shouldShowGoogleCast: Bool
    @Published var shouldShowAirplay: Bool
    @Published var subtitlesEnabled: Bool
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
    @Published var selectedAudioStreamIndex: Int
    @Published var selectedSubtitleStreamIndex: Int
    
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
    
    // Necessary PassthroughSubject to capture manual scrubbing from sliders
    let sliderScrubbingSubject = PassthroughSubject<VideoPlayerViewModel, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
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
         selectedSubtitleStreamIndex: Int) {
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
        
        self.sliderPercentageChanged(newValue: (item.userData?.playedPercentage ?? 0) / 100)
    }
    
    private func sliderPercentageChanged(newValue: Double) {
        let videoDuration = Double(item.runTimeTicks! / 10_000_000)
        let secondsScrubbedTo = round(sliderPercentage * videoDuration)
        let secondsScrubbedRemaining = videoDuration - secondsScrubbedTo
        
        leftLabelText = calculateTimeText(from: secondsScrubbedTo)
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
    
    func sendPlayReport(startTimeTicks: Int64) {
        
        self.startTimeTicks = startTimeTicks
        
        let startInfo = PlaybackStartInfo(canSeek: true,
                                          item: item,
                                          itemId: item.id,
                                          sessionId: response.playSessionId,
                                          mediaSourceId: item.id,
                                          audioStreamIndex: audioStreams.first(where: { $0.index! == response.mediaSources?.first?.defaultAudioStreamIndex! })?.index,
                                          subtitleStreamIndex: subtitleStreams.first(where: { $0.index! == response.mediaSources?.first?.defaultSubtitleStreamIndex ?? -1 })?.index,
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
                print(completion)
            } receiveValue: { _ in
                print("Playback start report sent!")
            }
            .store(in: &cancellables)
    }
    
    func sendProgressReport(ticks: Int64) {
        
        print("Progress ticks: \(ticks)")
        
        let progressInfo = PlaybackProgressInfo(canSeek: true,
                                                item: item,
                                                itemId: item.id,
                                                sessionId: response.playSessionId,
                                                mediaSourceId: item.id,
                                                audioStreamIndex: audioStreams.first(where: { $0.index! == response.mediaSources?.first?.defaultAudioStreamIndex! })?.index,
                                                subtitleStreamIndex: subtitleStreams.first(where: { $0.index! == response.mediaSources?.first?.defaultSubtitleStreamIndex ?? -1 })?.index,
                                                isPaused: false,
                                                isMuted: false,
                                                positionTicks: ticks,
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
                print(completion)
            } receiveValue: { _ in
                print("Playback progress sent!")
            }
            .store(in: &cancellables)
    }
    
    func sendStopReport(ticks: Int64) {
        
        let stopInfo = PlaybackStopInfo(item: item,
                                        itemId: item.id,
                                        sessionId: response.playSessionId,
                                        mediaSourceId: item.id,
                                        positionTicks: ticks,
                                        liveStreamId: nil,
                                        playSessionId: response.playSessionId,
                                        failed: nil,
                                        nextMediaType: nil,
                                        playlistItemId: "playlistItem0",
                                        nowPlayingQueue: nil)
        
        PlaystateAPI.reportPlaybackStopped(playbackStopInfo: stopInfo)
            .sink { completion in
                print(completion)
            } receiveValue: { _ in
                print("Playback stop report sent!")
            }
            .store(in: &cancellables)
    }
}
