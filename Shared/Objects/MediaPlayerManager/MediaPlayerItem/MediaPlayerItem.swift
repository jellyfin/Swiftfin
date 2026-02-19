//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
            guard let selectedAudioStreamIndex, selectedAudioStreamIndex != oldValue else { return }
            manager?.setAudioTrack(index: selectedAudioStreamIndex)
        }
    }

    @Published
    var selectedSubtitleStreamIndex: Int? = nil {
        didSet {
            guard let selectedIndex = indexMap[selectedSubtitleStreamIndex] else { return }
            if let proxy = manager?.proxy as? any VideoMediaPlayerProxy {
                proxy.setSubtitleStream(.init(index: selectedIndex))
            }
        }
    }

    /// Jellyfin stream index -> VLC track index. External subtitle entries are resolved at playback via `resolveExternalSubtitleIndexes`.
    private(set) var indexMap: [Int: Int]

    private var externalSubtitlesResolved = false

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
        initialAudioStreamIndex: Int? = nil,
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
        let mediaStreams = mediaSource.mediaStreams

        // TODO: Always force remux when external audio tracks are present
        /// External audio hidden — server has no deliveryURL for them
        self.audioStreams = mediaStreams?.filter { $0.type == .audio && $0.isExternal != true } ?? []
        self.subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []
        self.videoStreams = mediaStreams?.filter { $0.type == .video } ?? []

        self.indexMap = mediaStreams?.adjustedIndexMap(
            for: mediaSource.transcodingURL == nil ? .directPlay : .transcode,
            selectedAudioStreamIndex: initialAudioStreamIndex ?? 0
        ) ?? [:]

        super.init()

        selectedAudioStreamIndex = initialAudioStreamIndex
            ?? mediaSource.defaultAudioStreamIndex
            ?? mediaSource.mediaStreams?.first?.index ?? -1

        selectedSubtitleStreamIndex = mediaSource.defaultSubtitleStreamIndex ?? -1

        observers.append(MediaProgressObserver(item: self))
    }

    /// Resolves external subtitle VLC indexes from VLC's actual track list.
    /// Called once on first `.playing` state. Only needed for DirectPlay since the server may hide container tracks that affect playback child offsets.
    func resolveExternalSubtitleIndexes(vlcSubtitleTracks: [(index: Int, title: String)]) {
        guard !externalSubtitlesResolved else { return }
        externalSubtitlesResolved = true

        /// Only needed for DirectPlay — transcode external indexes are predicted correctly
        guard mediaSource.transcodingURL == nil else { return }

        let externalSubtitleStreams = subtitleStreams.filter { $0.isExternal == true }
        guard !externalSubtitleStreams.isEmpty else { return }

        indexMap = [MediaStream].resolveExternalSubtitleIndexes(
            vlcSubtitleTracks: vlcSubtitleTracks,
            currentIndexMap: indexMap,
            externalSubtitleStreams: externalSubtitleStreams
        )
    }
}
