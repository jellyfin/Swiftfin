//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import UIKit

extension BaseItemDto {
	func createVideoPlayerViewModel() -> AnyPublisher<[VideoPlayerViewModel], Error> {

		LogManager.shared.log.debug("Creating video player view model for item: \(id ?? "")")

		let builder = DeviceProfileBuilder()
		// TODO: fix bitrate settings
		let tempOverkillBitrate = 360_000_000
		builder.setMaxBitrate(bitrate: tempOverkillBitrate)
		let profile = builder.buildProfile()

		let playbackInfo = PlaybackInfoDto(userId: SessionManager.main.currentLogin.user.id,
		                                   maxStreamingBitrate: tempOverkillBitrate,
		                                   startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
		                                   deviceProfile: profile,
		                                   autoOpenLiveStream: true)

		return MediaInfoAPI.getPostedPlaybackInfo(itemId: self.id!,
		                                          userId: SessionManager.main.currentLogin.user.id,
		                                          maxStreamingBitrate: tempOverkillBitrate,
		                                          startTimeTicks: self.userData?.playbackPositionTicks ?? 0,
		                                          autoOpenLiveStream: true,
		                                          playbackInfoDto: playbackInfo)
			.map { response -> [VideoPlayerViewModel] in
				let mediaSources = response.mediaSources!

				var viewModels: [VideoPlayerViewModel] = []

				for currentMediaSource in mediaSources {
					let videoStream = currentMediaSource.mediaStreams?.filter { $0.type == .video }.first
					let audioStreams = currentMediaSource.mediaStreams?.filter { $0.type == .audio } ?? []
					let subtitleStreams = currentMediaSource.mediaStreams?.filter { $0.type == .subtitle } ?? []

					let defaultAudioStream = audioStreams.first(where: { $0.index! == currentMediaSource.defaultAudioStreamIndex! })

					let defaultSubtitleStream = subtitleStreams
						.first(where: { $0.index! == currentMediaSource.defaultSubtitleStreamIndex ?? -1 })

					// MARK: Build Streams

					let directStreamURL: URL
					let transcodedStreamURL: URLComponents?
					var hlsStreamURL: URL
					let mediaSourceID: String
					let streamType: ServerStreamType

					if mediaSources.count > 1 {
						mediaSourceID = currentMediaSource.id!
					} else {
						mediaSourceID = self.id!
					}

					let directStreamBuilder = VideosAPI.getVideoStreamWithRequestBuilder(itemId: self.id!,
					                                                                     _static: true,
					                                                                     tag: self.etag,
					                                                                     playSessionId: response.playSessionId,
					                                                                     minSegments: 6,
					                                                                     mediaSourceId: mediaSourceID)
					directStreamURL = URL(string: directStreamBuilder.URLString)!

					if let transcodeURL = currentMediaSource.transcodingUrl {
						streamType = .transcode
						transcodedStreamURL = URLComponents(string: SessionManager.main.currentLogin.server.currentURI
							.appending(transcodeURL))!
					} else {
						streamType = .direct
						transcodedStreamURL = nil
					}

					let hlsStreamBuilder = DynamicHlsAPI.getMasterHlsVideoPlaylistWithRequestBuilder(itemId: id ?? "",
					                                                                                 mediaSourceId: id ?? "",
					                                                                                 _static: true,
					                                                                                 tag: currentMediaSource.eTag,
					                                                                                 deviceProfileId: nil,
					                                                                                 playSessionId: response.playSessionId,
					                                                                                 segmentContainer: "ts",
					                                                                                 segmentLength: nil,
					                                                                                 minSegments: 2,
					                                                                                 deviceId: UIDevice.vendorUUIDString,
					                                                                                 audioCodec: audioStreams
					                                                                                 	.compactMap(\.codec)
					                                                                                 	.joined(separator: ","),
					                                                                                 breakOnNonKeyFrames: true,
					                                                                                 requireAvc: true,
					                                                                                 transcodingMaxAudioChannels: 6,
					                                                                                 videoCodec: videoStream?.codec,
					                                                                                 videoStreamIndex: videoStream?.index,
					                                                                                 enableAdaptiveBitrateStreaming: true)

					var hlsStreamComponents = URLComponents(string: hlsStreamBuilder.URLString)!
					hlsStreamComponents.addQueryItem(name: "api_key", value: SessionManager.main.currentLogin.user.accessToken)

					hlsStreamURL = hlsStreamComponents.url!

					// MARK: VidoPlayerViewModel Creation

					var subtitle: String?

					// MARK: Attach media content to self

					var modifiedSelfItem = self
					modifiedSelfItem.mediaStreams = currentMediaSource.mediaStreams

					// TODO: other forms of media subtitle
					if self.itemType == .episode {
						if let seriesName = self.seriesName, let episodeLocator = self.getEpisodeLocator() {
							subtitle = "\(seriesName) - \(episodeLocator)"
						}
					}

					let subtitlesEnabled = defaultSubtitleStream != nil

					let shouldShowAutoPlay = Defaults[.shouldShowAutoPlay] && itemType == .episode
					let autoplayEnabled = Defaults[.autoplayEnabled] && shouldShowAutoPlay

					let overlayType = Defaults[.overlayType]

					let shouldShowPlayPreviousItem = Defaults[.shouldShowPlayPreviousItem] && itemType == .episode
					let shouldShowPlayNextItem = Defaults[.shouldShowPlayNextItem] && itemType == .episode

					var fileName: String?
					if let lastInPath = currentMediaSource.path?.split(separator: "/").last {
						fileName = String(lastInPath)
					}

					let videoPlayerViewModel = VideoPlayerViewModel(item: modifiedSelfItem,
					                                                title: modifiedSelfItem.name ?? "",
					                                                subtitle: subtitle,
					                                                directStreamURL: directStreamURL,
					                                                transcodedStreamURL: transcodedStreamURL?.url,
					                                                hlsStreamURL: hlsStreamURL,
					                                                streamType: streamType,
					                                                response: response,
					                                                audioStreams: audioStreams,
					                                                subtitleStreams: subtitleStreams,
					                                                chapters: modifiedSelfItem.chapters ?? [],
					                                                selectedAudioStreamIndex: defaultAudioStream?.index ?? -1,
					                                                selectedSubtitleStreamIndex: defaultSubtitleStream?.index ?? -1,
					                                                subtitlesEnabled: subtitlesEnabled,
					                                                autoplayEnabled: autoplayEnabled,
					                                                overlayType: overlayType,
					                                                shouldShowPlayPreviousItem: shouldShowPlayPreviousItem,
					                                                shouldShowPlayNextItem: shouldShowPlayNextItem,
					                                                shouldShowAutoPlay: shouldShowAutoPlay,
					                                                container: currentMediaSource.container ?? "",
					                                                filename: fileName,
					                                                versionName: currentMediaSource.name)

					viewModels.append(videoPlayerViewModel)
				}

				return viewModels
			}
			.eraseToAnyPublisher()
	}
}
