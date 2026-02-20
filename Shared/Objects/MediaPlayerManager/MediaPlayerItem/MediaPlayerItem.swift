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
            manager?.setTrack(type: .audio, from: oldValue, to: selectedAudioStreamIndex)
        }
    }

    @Published
    var selectedSubtitleStreamIndex: Int? = nil {
        didSet {
            guard selectedSubtitleStreamIndex != oldValue else { return }
            manager?.setTrack(type: .subtitle, from: oldValue, to: selectedSubtitleStreamIndex)
        }
    }

    /// Jellyfin stream index → player track index
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
        initialSubtitleStreamIndex: Int? = nil,
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
        let isTranscoding = mediaSource.transcodingURL != nil

        // TODO: Fix External Audio Tracks & Re-Enable
        self.audioStreams = mediaStreams?.filter { $0.type == .audio && $0.isExternal != true } ?? []
        self.subtitleStreams = mediaStreams?.filter { $0.type == .subtitle && $0.deliveryMethod != .drop } ?? []
        self.videoStreams = mediaStreams?.filter { $0.type == .video } ?? []

        let resolvedAudioStreamIndex = initialAudioStreamIndex
            ?? mediaSource.defaultAudioStreamIndex
            ?? mediaSource.mediaStreams?.first(where: { $0.type == .audio })?.index ?? 0

        self.indexMap = mediaStreams?.buildIndexMap(
            for: isTranscoding ? .transcode : .directPlay,
            selectedAudioStreamIndex: resolvedAudioStreamIndex
        ) ?? [:]

        super.init()

        selectedAudioStreamIndex = resolvedAudioStreamIndex

        selectedSubtitleStreamIndex = initialSubtitleStreamIndex
            ?? mediaSource.defaultSubtitleStreamIndex
            ?? -1

        observers.append(MediaProgressObserver(item: self))
    }

    /// Encoded or image-based (PGS) subtitles require a server rebuild to burn in
    func isRebuildRequired(from oldIndex: Int?, to newIndex: Int?) -> Bool {
        let needsRebuild: (MediaStream?) -> Bool = { stream in
            guard let stream else { return false }
            return stream.deliveryMethod == .encode || stream.isTextSubtitleStream != true
        }

        let oldStream = subtitleStreams.first(where: { $0.index == oldIndex })
        let newStream: MediaStream? = {
            guard let idx = newIndex, idx != -1 else { return nil }
            return subtitleStreams.first(where: { $0.index == idx })
        }()

        return needsRebuild(oldStream) || needsRebuild(newStream)
    }

    /// Switch subtitle track directly without rebuilding
    func switchSubtitleTrack(index: Int?) {
        let playerIndex: Int
        if index == nil || index == -1 {
            playerIndex = -1
        } else if let mapped = indexMap[index] {
            playerIndex = mapped
        } else {
            return
        }

        if let proxy = manager?.proxy as? any VideoMediaPlayerProxy {
            proxy.setSubtitleStream(.init(index: playerIndex))
        }
    }

    /// Resolve sidecar subtitle indexes once the player reports its actual tracks
    func getSubtitleIndexes(subtitleTracks: [(index: Int, title: String)]) {
        guard !externalSubtitlesResolved else { return }
        externalSubtitlesResolved = true

        let playbackChildren = subtitleStreams.sidecarSubtitles
        guard playbackChildren.isNotEmpty else { return }

        indexMap = [MediaStream].resolveIndexMap(
            into: indexMap,
            playbackChildren: playbackChildren,
            subtitleTracks: subtitleTracks,
            isTranscoding: mediaSource.transcodingURL != nil
        )

        // re-apply current subtitle now that we have real indexes
        if let currentSubtitle = selectedSubtitleStreamIndex,
           let playerIndex = indexMap[currentSubtitle]
        {
            if let proxy = manager?.proxy as? any VideoMediaPlayerProxy {
                proxy.setSubtitleStream(.init(index: playerIndex))
            }
        }
    }
}
