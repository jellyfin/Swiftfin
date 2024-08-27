//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Files
import Foundation
import JellyfinAPI
import MediaPlayer
import UIKit
import VLCUI

// class VideoPlayerViewModel: ViewModel {
//
//    let playbackURL: URL
//    let item: BaseItemDto
//    let mediaSource: MediaSourceInfo
//    let playSessionID: String
//    let videoStreams: [MediaStream]
//    let audioStreams: [MediaStream]
//    let subtitleStreams: [MediaStream]
//    let selectedAudioStreamIndex: Int
//    let selectedSubtitleStreamIndex: Int
//    let chapters: [ChapterInfo.FullInfo]
//    let streamType: StreamType
//
//    private(set) var nowPlayingImage: UIImage?
//
//    var nowPlayingMetadata: NowPlayableStaticMetadata {
//        let artwork = MPMediaItemArtwork(boundsSize: .init(width: 170, height: 300)) { size in
//            if let nowPlayingImage = self.nowPlayingImage {
//                return nowPlayingImage
//            } else if let blurHash = self.item.blurHash(.primary) {
//                return UIImage(blurHash: blurHash, size: size)!
//            } else {
//                return UIImage(blurHash: "", size: size)!
//            }
//        }
//
//        return .init(
//            mediaType: .audio,
//            title: item.displayTitle,
//            artwork: artwork
//        )
//    }
//
//    var hlsPlaybackURL: URL {
//
//        let parameters = Paths.GetMasterHlsVideoPlaylistParameters(
//            isStatic: true,
//            tag: mediaSource.eTag,
//            playSessionID: playSessionID,
//            segmentContainer: "mp4",
//            minSegments: 2,
//            mediaSourceID: mediaSource.id!,
//            deviceID: UIDevice.vendorUUIDString,
//            audioCodec: mediaSource.audioStreams?
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            isBreakOnNonKeyFrames: true,
//            requireAvc: false,
//            transcodingMaxAudioChannels: 8,
//            videoCodec: videoStreams
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            videoStreamIndex: videoStreams.first?.index,
//            enableAdaptiveBitrateStreaming: true
//        )
//        let request = Paths.getMasterHlsVideoPlaylist(
//            itemID: item.id!,
//            parameters: parameters
//        )
//
//        return URLComponents(
//            url: userSession.client.fullURL(with: request)!,
//            resolvingAgainstBaseURL: false
//        )!
//            .addingQueryItem(key: "api_key", value: userSession.user.accessToken)
//            .url!
//    }
//
//    // TODO: should start time be from the media source instead?
//    var vlcVideoPlayerConfiguration: VLCVideoPlayer.Configuration {
//        let configuration = VLCVideoPlayer.Configuration(url: playbackURL)
//        configuration.autoPlay = true
//        configuration.startTime = .seconds(max(0, item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]))
//        configuration.audioIndex = .absolute(selectedAudioStreamIndex)
//        configuration.subtitleIndex = .absolute(selectedSubtitleStreamIndex)
//        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])
//        configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)
//
//        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
//            configuration.subtitleFont = .absolute(font)
//        }
//
//        configuration.playbackChildren = subtitleStreams
//            .filter { $0.deliveryMethod == .external }
//            .compactMap(\.asPlaybackChild)
//
//        return configuration
//    }
//
//    init(
//        playbackURL: URL,
//        item: BaseItemDto,
//        mediaSource: MediaSourceInfo,
//        playSessionID: String,
//        videoStreams: [MediaStream],
//        audioStreams: [MediaStream],
//        subtitleStreams: [MediaStream],
//        selectedAudioStreamIndex: Int,
//        selectedSubtitleStreamIndex: Int,
//        chapters: [ChapterInfo.FullInfo],
//        streamType: StreamType
//    ) {
//        self.item = item
//        self.mediaSource = mediaSource
//        self.playSessionID = playSessionID
//        self.playbackURL = playbackURL
//        self.videoStreams = videoStreams
//        self.audioStreams = audioStreams
//            .adjustAudioForExternalSubtitles(externalMediaStreamCount: subtitleStreams.filter { $0.isExternal ?? false }.count)
//        self.subtitleStreams = subtitleStreams
//            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)
//        self.selectedAudioStreamIndex = selectedAudioStreamIndex
//        self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
//        self.chapters = chapters
//        self.streamType = streamType
//        super.init()
//    }
//
//    func chapter(from seconds: Int) -> ChapterInfo.FullInfo? {
//        chapters.first(where: { $0.secondsRange.contains(seconds) })
//    }
//
//    func getNowPlayingImage(_ completion: @escaping () -> Void) {
//
//        let imageSource = item.portraitImageSources(maxWidth: 200)
//        guard let url = imageSource.compacted(using: \.url).first?.url else { return }
//
//        // TODO: look at Nuke loading for cache use
//        DispatchQueue.global().async { [weak self] in
//            if let data = try? Data(contentsOf: url) {
//                if let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        guard let self else { return }
//                        self.nowPlayingImage = image
//                        completion()
//                    }
//                }
//            }
//        }
//    }
// }
//
// extension VideoPlayerViewModel: Equatable {
//
//    static func == (lhs: VideoPlayerViewModel, rhs: VideoPlayerViewModel) -> Bool {
//        lhs.item == rhs.item &&
//            lhs.playbackURL == rhs.playbackURL
//    }
// }
