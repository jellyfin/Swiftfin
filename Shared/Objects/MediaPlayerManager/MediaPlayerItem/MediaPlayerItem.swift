//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: get preview image for current manager seconds?
//       - would make scrubbing image possibly ready before scrubbing
// TODO: fix leaks
//       - made from publishers of observers not being cancelled

@MainActor
class MediaPlayerItem: ViewModel, MediaPlayerObserver {

    typealias ThumbnailProvider = () async -> UIImage?

    @Published
    var selectedAudioStreamIndex: Int? = nil {
        didSet {
            if let proxy = manager?.proxy as? any VideoMediaPlayerProxy {
                proxy.setAudioStream(.init(index: selectedAudioStreamIndex))
            }
        }
    }

    @Published
    var selectedSubtitleStreamIndex: Int? = nil {
        didSet {
            if let proxy = manager?.proxy as? any VideoMediaPlayerProxy {
                proxy.setSubtitleStream(.init(index: selectedSubtitleStreamIndex))
            }
        }
    }

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }
        }
    }

    var observers: [any MediaPlayerObserver] = []

    let baseItem: BaseItemDto
    let mediaSource: MediaSourceInfo
    let playSessionID: String
    let previewImageProvider: (any PreviewImageProvider)?
    let thumbnailProvider: ThumbnailProvider?
    let url: URL

    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let videoStreams: [MediaStream]

    let requestedBitrate: PlaybackBitrate

    // MARK: init

    init(
        baseItem: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        url: URL,
        requestedBitrate: PlaybackBitrate = .max,
        previewImageProvider: (any PreviewImageProvider)? = nil,
        thumbnailProvider: ThumbnailProvider? = nil
    ) {
        self.baseItem = baseItem
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.requestedBitrate = requestedBitrate
        self.previewImageProvider = previewImageProvider
        self.thumbnailProvider = thumbnailProvider
        self.url = url

        let adjustedMediaStreams = mediaSource.mediaStreams?.adjustedTrackIndexes(
            for: mediaSource.transcodingURL == nil ? .directPlay : .transcode,
            selectedAudioStreamIndex: mediaSource.defaultAudioStreamIndex ?? 0
        )

        let audioStreams = adjustedMediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = adjustedMediaStreams?.filter { $0.type == .subtitle } ?? []
        let videoStreams = adjustedMediaStreams?.filter { $0.type == .video } ?? []

        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
        self.videoStreams = videoStreams

        super.init()

        selectedAudioStreamIndex = mediaSource.defaultAudioStreamIndex ?? -1
        selectedSubtitleStreamIndex = mediaSource.defaultSubtitleStreamIndex ?? -1

        observers.append(MediaProgressObserver(item: self))
    }
}
