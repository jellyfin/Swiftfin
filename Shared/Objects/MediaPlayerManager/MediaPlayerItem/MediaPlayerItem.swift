//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

class MediaPlayerItem: ViewModel, MediaPlayerObserver {

    typealias ThumnailProvider = () async -> UIImage?

    @Published
    var selectedAudioStreamIndex: Int? = nil {
        didSet {
            manager?.proxy?.setAudioStream(.init(index: selectedAudioStreamIndex))
        }
    }

    @Published
    var selectedSubtitleStreamIndex: Int? = nil {
        didSet {
            manager?.proxy?.setSubtitleStream(.init(index: selectedSubtitleStreamIndex))
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
    var supplements: [any MediaPlayerSupplement] = []

    let baseItem: BaseItemDto
    let mediaSource: MediaSourceInfo
    let playSessionID: String
    let thumbnailProvider: ThumnailProvider?
    let url: URL

    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let videoStreams: [MediaStream]

    // MARK: init

    init(
        baseItem: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        url: URL,
        thumbnailProvider: ThumnailProvider? = nil
    ) {
        self.baseItem = baseItem
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
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
        // TODO: move to manager?
        supplements.append(MediaInfoSupplement(item: baseItem))

        let chapters = baseItem.fullChapterInfo

        if chapters.isNotEmpty {
            supplements.append(
                MediaChaptersSupplement(
                    chapters: baseItem.fullChapterInfo
                )
            )
        }
    }
}
