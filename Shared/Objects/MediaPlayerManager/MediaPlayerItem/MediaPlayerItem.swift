//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
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
    let deviceProfile: DeviceProfile = .init()
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
        self.subtitleStreams = mediaStreams?.filter {
            $0.type == .subtitle
                && $0.deliveryMethod != .drop
                && !(Defaults[.VideoPlayer.Playback.compatibilityMode] == .directPlay
                    && $0.isExternal == true
                    && $0.isTextSubtitleStream != true)
        } ?? []
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

    /// Decides whether a track change can be performed by the player in place, or whether the server must produce a new stream.
    func isRebuildRequired(type: MediaStreamType, from oldIndex: Int?, to newIndex: Int?) -> Bool {
        let isTranscoding = mediaSource.transcodingURL != nil

        // Disabling a track is ALWAYS a local-only operation.
        guard let newIndex, newIndex != -1 else { return false }

        switch type {
        case .audio:

            // Transcodes contain a single audio track and MUST rebuild.
            if isTranscoding { return true }

            guard let newStream = audioStreams.first(where: { $0.index == newIndex }) else { return true }

            // TODO: When audio playback exists then get the type dynamically.
            return !deviceProfile.canPlay(
                type: .video,
                audioCodec: newStream.codec,
                container: mediaSource.container
            )

        case .subtitle:
            // Optional (do not guard) since this could be -1 for disabled.
            let oldStream = oldIndex.flatMap { idx in subtitleStreams.first { $0.index == idx } }

            // Transitioning away from encoded subtitles always requires a rebuild so the server stops burning them into the video.
            if oldStream?.deliveryMethod == .encode { return true }

            // Catch if the new stream doesn't exist. If non-existent this will fallback to -1 and disable locally.
            guard let newStream = subtitleStreams.first(where: { $0.index == newIndex }) else { return false }

            if newStream.isExternal == true {

                // External subtitles can only be loaded as sidecars when the profile allows external or HLS delivery for the format.
                // E.G, This should disable external PGS for VLC since VLC cannot play them.
                return !(deviceProfile.canPlay(subtitleFormat: newStream.codec, method: .external)
                    || deviceProfile.canPlay(subtitleFormat: newStream.codec, method: .hls))
            }

            // Embedded subtitles are in the source container.
            // Only reachable while direct-playing AND when the profile supports embed delivery.
            return isTranscoding || !deviceProfile.canPlay(subtitleFormat: newStream.codec, method: .embed)

        default:
            return false
        }
    }

    /// Switches an audio, subtitle, or lyric* track in the player without rebuilding the stream.
    /// *Lyrics stubs are there but needs a `MediaPlayerLyricTrackConfigurable`
    func switchTrack(type: MediaStreamType, index: Int?) {
        let playerIndex: Int
        if index == nil || index == -1 {
            playerIndex = -1
        } else if let mapped = indexMap[index] {
            playerIndex = mapped
        } else {
            return
        }

        switch type {
        case .audio:
            guard let proxy = manager?.proxy as? any MediaPlayerAudioTrackConfigurable else { return }
            proxy.setAudioStream(.init(index: playerIndex))
        case .subtitle:
            guard let proxy = manager?.proxy as? any MediaPlayerSubtitleTrackConfigurable else { return }
            proxy.setSubtitleStream(.init(index: playerIndex))
        case .lyric:

            // TODO: Enable for Audio Player when Lyrics are needed.
            // guard let proxy = manager?.proxy as? any MediaPlayerLyricTrackConfigurable else { return }
            // proxy.setLyricStream(.init(index: playerIndex))
            return
        default:
            return
        }
    }

    /// Get subtitle mapped subtitle track indexes from `playbackChildren`
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

        switchTrack(type: .subtitle, index: selectedSubtitleStreamIndex)
    }
}
