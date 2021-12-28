//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Combine
import JellyfinAPI
import UIKit

extension BaseItemDto {
    func createVideoPlayerViewModel() -> AnyPublisher<VideoPlayerViewModel, Error> {
        let builder = DeviceProfileBuilder()
        // TODO: fix bitrate settings
        builder.setMaxBitrate(bitrate: 60000000)
        let profile = builder.buildProfile()
        
        let playbackInfo = PlaybackInfoDto(userId: SessionManager.main.currentLogin.user.id,
                                           maxStreamingBitrate: 60000000,
                                           startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
                                           deviceProfile: profile,
                                           autoOpenLiveStream: true)
        
        return MediaInfoAPI.getPostedPlaybackInfo(itemId: self.id!,
                                           userId: SessionManager.main.currentLogin.user.id,
                                           maxStreamingBitrate: 60000000,
                                           startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
                                           autoOpenLiveStream: true,
                                           playbackInfoDto: playbackInfo)
            .map({ response -> VideoPlayerViewModel in
                let mediaSource = response.mediaSources!.first!
                
                let audioStreams = mediaSource.mediaStreams?.filter({ $0.type == .audio }) ?? []
                let subtitleStreams = mediaSource.mediaStreams?.filter({ $0.type == .subtitle }) ?? []
                
                let defaultAudioStream = audioStreams.first(where: { $0.index! == mediaSource.defaultAudioStreamIndex! })
                
                let defaultSubtitleStream = subtitleStreams.first(where: { $0.index! == mediaSource.defaultSubtitleStreamIndex ?? -1 })
                
                let videoStream = mediaSource.mediaStreams!.first(where: { $0.type! == MediaStreamType.video })
                
                let audioCodecs = mediaSource.mediaStreams!.filter({ $0.type! == MediaStreamType.audio }).map({ $0.codec! })
                
                // MARK: basic stream
                var streamURL = URLComponents(string: SessionManager.main.currentLogin.server.currentURI)!
                streamURL.path = "/Videos/\(self.id!)/stream"

                streamURL.addQueryItem(name: "Static", value: "true")
                streamURL.addQueryItem(name: "MediaSourceId", value: self.id!)
                streamURL.addQueryItem(name: "Tag", value: self.etag)
                streamURL.addQueryItem(name: "MinSegments", value: "6")
                
                // MARK: hls stream
                var hlsURL = URLComponents(string: SessionManager.main.currentLogin.server.currentURI)!
                hlsURL.path = "/videos/\(self.id!)/master.m3u8"

                hlsURL.addQueryItem(name: "DeviceId", value: UIDevice.vendorUUIDString)
                hlsURL.addQueryItem(name: "MediaSourceId", value: self.id!)
                hlsURL.addQueryItem(name: "VideoCodec", value: videoStream?.codec!)
                hlsURL.addQueryItem(name: "AudioCodec", value: audioCodecs.joined(separator: ","))
                hlsURL.addQueryItem(name: "AudioStreamIndex", value: "\(defaultAudioStream!.index!)")
                hlsURL.addQueryItem(name: "VideoBitrate", value: "\(videoStream!.bitRate!)")
                hlsURL.addQueryItem(name: "AudioBitrate", value: "\(defaultAudioStream!.bitRate!)")
                hlsURL.addQueryItem(name: "PlaySessionId", value: response.playSessionId!)
                hlsURL.addQueryItem(name: "TranscodingMaxAudioChannels", value: "6")
                hlsURL.addQueryItem(name: "RequireAvc", value: "false")
                hlsURL.addQueryItem(name: "Tag", value: mediaSource.eTag!)
                hlsURL.addQueryItem(name: "SegmentContainer", value: "ts")
                hlsURL.addQueryItem(name: "MinSegments", value: "2")
                hlsURL.addQueryItem(name: "BreakOnNonKeyFrames", value: "true")
                hlsURL.addQueryItem(name: "TranscodeReasons", value: "VideoCodecNotSupported,AudioCodecNotSupported")
                hlsURL.addQueryItem(name: "api_key", value: SessionManager.main.currentLogin.user.accessToken)
                
                if defaultSubtitleStream?.index != nil {
                    hlsURL.addQueryItem(name: "SubtitleMethod", value: "Encode")
                    hlsURL.addQueryItem(name: "SubtitleStreamIndex", value: "\(defaultSubtitleStream!.index!)")
                }
                
                let videoPlayerViewModel = VideoPlayerViewModel(item: self,
                                                                title: self.name!,
                                                                subtitle: self.seriesName,
                                                                streamURL: streamURL.url!,
                                                                hlsURL: hlsURL.url!,
                                                                response: response,
                                                                audioStreams: audioStreams,
                                                                subtitleStreams: subtitleStreams,
                                                                defaultAudioStreamIndex: defaultAudioStream?.index ?? -1,
                                                                defaultSubtitleStreamIndex: defaultSubtitleStream?.index ?? -1,
                                                                playerState: .playing,
                                                                shouldShowGoogleCast: false,
                                                                shouldShowAirplay: false,
                                                                subtitlesEnabled: defaultAudioStream?.index != nil,
                                                                sliderPercentage: (self.userData?.playedPercentage ?? 0) / 100,
                                                                selectedAudioStreamIndex: defaultAudioStream?.index ?? -1,
                                                                selectedSubtitleStreamIndex: defaultSubtitleStream?.index ?? -1)
                
                return videoPlayerViewModel
            })
            .eraseToAnyPublisher()
    }
}
