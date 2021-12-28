//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Combine
import Foundation
import JellyfinAPI
import UIKit

class ItemViewModel: ViewModel {

    @Published var item: BaseItemDto
    @Published var playButtonItem: BaseItemDto?
    @Published var similarItems: [BaseItemDto] = []
    @Published var isWatched = false
    @Published var isFavorited = false
    var itemVideoPlayerViewModel: VideoPlayerViewModel?

    init(item: BaseItemDto) {
        self.item = item

        switch item.itemType {
        case .episode, .movie:
            self.playButtonItem = item
        default: ()
        }

        isFavorited = item.userData?.isFavorite ?? false
        isWatched = item.userData?.played ?? false
        super.init()

        getSimilarItems()
        
        self.createVideoPlayerViewModel(item: item)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { videoPlayerViewModel in
                self.itemVideoPlayerViewModel = videoPlayerViewModel
            }
            .store(in: &cancellables)
    }

    func playButtonText() -> String {
        return item.getItemProgressString() == "" ? L10n.play : item.getItemProgressString()
    }

    func getItemDisplayName() -> String {
        return item.name ?? ""
    }

    func shouldDisplayRuntime() -> Bool {
        return true
    }

    func getSimilarItems() {
        LibraryAPI.getSimilarItems(itemId: item.id!, userId: SessionManager.main.currentLogin.user.id, limit: 20, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people])
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.similarItems = response.items ?? []
            })
            .store(in: &cancellables)
    }

    func updateWatchState() {
        if isWatched {
            PlaystateAPI.markUnplayedItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestError(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isWatched = false
                })
                .store(in: &cancellables)
        } else {
            PlaystateAPI.markPlayedItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestError(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isWatched = true
                })
                .store(in: &cancellables)
        }
    }

    func updateFavoriteState() {
        if isFavorited {
            UserLibraryAPI.unmarkFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestError(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isFavorited = false
                })
                .store(in: &cancellables)
        } else {
            UserLibraryAPI.markFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
                .trackActivity(loading)
                .sink(receiveCompletion: { [weak self] completion in
                    self?.handleAPIRequestError(completion: completion)
                }, receiveValue: { [weak self] _ in
                    self?.isFavorited = true
                })
                .store(in: &cancellables)
        }
    }
    
    func createVideoPlayerViewModel(item: BaseItemDto) -> AnyPublisher<VideoPlayerViewModel, Error> {
        let builder = DeviceProfileBuilder()
        // TODO: fix bitrate settings
        builder.setMaxBitrate(bitrate: 60000000)
        let profile = builder.buildProfile()
        
        let playbackInfo = PlaybackInfoDto(userId: SessionManager.main.currentLogin.user.id,
                                           maxStreamingBitrate: 60000000,
                                           startTimeTicks: item.userData?.playbackPositionTicks ?? 0,
                                           deviceProfile: profile,
                                           autoOpenLiveStream: true)
        
        return MediaInfoAPI.getPostedPlaybackInfo(itemId: item.id!,
                                           userId: SessionManager.main.currentLogin.user.id,
                                           maxStreamingBitrate: 60000000,
                                           startTimeTicks: item.userData?.playbackPositionTicks ?? 0,
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
                streamURL.path = "/Videos/\(item.id!)/stream"

                streamURL.addQueryItem(name: "Static", value: "true")
                streamURL.addQueryItem(name: "MediaSourceId", value: item.id!)
                streamURL.addQueryItem(name: "Tag", value: item.etag)
                streamURL.addQueryItem(name: "MinSegments", value: "6")
                
                // MARK: hls stream
                var hlsURL = URLComponents(string: SessionManager.main.currentLogin.server.currentURI)!
                hlsURL.path = "/videos/\(item.id!)/master.m3u8"

                hlsURL.addQueryItem(name: "DeviceId", value: UIDevice.vendorUUIDString)
                hlsURL.addQueryItem(name: "MediaSourceId", value: item.id!)
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

//                    startURL.queryItems?.append(URLQueryItem(name: "SubtitleCodec", value: "\(defaultSubtitleStream!.codec!)"))
                
                let videoPlayerViewModel = VideoPlayerViewModel(item: item,
                                                                title: item.name!,
                                                                subtitle: item.seriesName,
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
                                                                sliderPercentage: (item.userData?.playedPercentage ?? 0) / 100,
                                                                selectedAudioStreamIndex: defaultAudioStream?.index ?? -1,
                                                                selectedSubtitleStreamIndex: defaultSubtitleStream?.index ?? -1)
                
                return videoPlayerViewModel
            })
            .eraseToAnyPublisher()
    }
}
