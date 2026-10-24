//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import Observation
import SwiftUI

@MainActor
@Observable
final class MediaPlayerItem {

    typealias ThumbnailProvider = () async -> UIImage?

    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let videoStreams: [MediaStream]

    private(set) var automaticTrackDefaults: MediaPlaybackPreferences.Selection
    let chapters: [ChapterInfo.FullInfo]
    let deviceProfile: DeviceProfile
    private(set) var indexMap: MediaTrackIndexMap

    weak var mediaSession: MediaSession? {
        didSet {
            if mediaSession == nil {
                mediaPreferences = nil
                replaySubtitles = nil
                temporarySubtitleTracks = nil
                segmentObservation = nil
                segments = nil
                temporaryFiles.remove()
            } else if oldValue == nil, let previewImageProvider {
                temporaryFiles.download(for: previewImageProvider)
            }
        }
    }

    let mediaSource: MediaSourceInfo
    let playSessionID: String
    let requestedBitrate: PlaybackBitrate
    private let runtimeTicks: Int?

    var audioStreamIndex: Int?
    var subtitleStreamIndex: Int?
    var secondarySubtitleStreamIndex: Int? = -1
    var configuration = Configuration()
    var playbackIntent: PlaybackIntent?
    private(set) var segments: MediaSegmentObserver?

    @ObservationIgnored
    private var segmentObservation: AnyCancellable?

    @ObservationIgnored
    private(set) var mediaPreferences: MediaPlayerItemPreferences?
    @ObservationIgnored
    private(set) var replaySubtitles: MediaPlayerItemReplaySubtitles?

    private let sharedItem: ItemEntry
    private let startPositionTicks: Int?

    /// Replay captions never change the persistent selection or Jellyfin reports.
    private(set) var temporarySubtitleTracks: SubtitleTrackSelection?

    let previewImageProvider: PreviewImageProvider?
    let temporaryFiles: PlaybackTemporaryFiles
    let thumbnailProvider: ThumbnailProvider?
    let url: URL

    var effectiveSubtitleStreamIndex: Int {
        temporarySubtitleTracks?.primary ?? selectedSubtitleStreamIndex ?? -1
    }

    var effectiveSecondarySubtitleStreamIndex: Int {
        temporarySubtitleTracks?.secondary ?? selectedSecondarySubtitleStreamIndex ?? -1
    }

    func setTemporarySubtitleTracks(_ tracks: SubtitleTrackSelection?, apply: Bool = true) {
        temporarySubtitleTracks = tracks

        if apply {
            applySelectedSubtitleTracks()
        }
    }

    private func applySelectedSubtitleTracks() {
        switchTrack(type: .subtitle, index: effectiveSubtitleStreamIndex)

        (mediaSession?.player as? MediaPlayerSecondarySubtitleProviding)?.setSecondarySubtitle(
            indexMap.playerIndex(for: effectiveSecondarySubtitleStreamIndex).flatMap { $0 >= 0 ? $0 : nil }
        )
    }

    /// Secondary subtitles must play locally without changing the server's burn-in selection.
    var secondarySubtitleStreams: [MediaStream] {
        subtitleStreams.filter {
            guard let index = $0.index, index >= 0, index != selectedSubtitleStreamIndex,
                  $0.deliveryMethod != .encode else { return false }

            return !isRebuildRequired(type: .subtitle, from: -1, to: index)
        }
    }

    /// Applies local playback overrides to the latest shared metadata
    var baseItem: BaseItemDto {
        var value = sharedItem.snapshot
        value.runTimeTicks = runtimeTicks ?? value.runTimeTicks

        if let startPositionTicks {
            var data = value.userData ?? UserItemDataDto(key: value.id ?? "")
            data.playbackPositionTicks = startPositionTicks
            value.userData = data
        }

        return value
    }

    init(
        baseItem: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        url: URL,
        requestedBitrate: PlaybackBitrate = .max,
        deviceProfile: DeviceProfile,
        initialAudioStreamIndex: Int? = nil,
        initialSubtitleStreamIndex: Int? = nil,
        initialSecondarySubtitleStreamIndex: Int? = nil,
        automaticTrackDefaults: MediaPlaybackPreferences.Selection? = nil,
        chapters: [ChapterInfo.FullInfo],
        temporaryFiles: PlaybackTemporaryFiles,
        previewImageProvider: PreviewImageProvider?,
        thumbnailProvider: ThumbnailProvider? = nil
    ) {
        self.sharedItem = SharedBaseItem(wrappedValue: baseItem).entry
        self.startPositionTicks = baseItem.userData?.playbackPositionTicks
        self.runtimeTicks = mediaSource.runTimeTicks ?? baseItem.runTimeTicks
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.requestedBitrate = requestedBitrate
        self.deviceProfile = deviceProfile
        self.chapters = chapters
        self.temporaryFiles = temporaryFiles
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
        } ?? []

        self.videoStreams = mediaStreams?.filter { $0.type == .video } ?? []

        self.automaticTrackDefaults = .init(
            audio: automaticTrackDefaults?.audio ?? mediaSource.defaultAudioStreamIndex
                ?? audioStreams.first(where: { $0.isDefault == true })?.index ?? audioStreams.first?.index,
            subtitle: automaticTrackDefaults?.subtitle ?? mediaSource.defaultSubtitleStreamIndex
        )

        let resolvedAudioStreamIndex: Int = initialAudioStreamIndex
            ?? mediaSource.defaultAudioStreamIndex
            ?? mediaSource.mediaStreams?.first(where: { $0.type == .audio })?.index ?? 0

        self.indexMap = MediaTrackIndexMap.build(
            from: mediaStreams ?? [],
            for: isTranscoding ? .transcode : .directPlay,
            selectedAudioStreamIndex: resolvedAudioStreamIndex
        )

        audioStreamIndex = resolvedAudioStreamIndex

        subtitleStreamIndex = initialSubtitleStreamIndex
            ?? mediaSource.defaultSubtitleStreamIndex
            ?? -1

        if let index = initialSecondarySubtitleStreamIndex,
           secondarySubtitleStreams.contains(where: { $0.index == index })
        {
            secondarySubtitleStreamIndex = index
        }
    }

    // Observer cancellation must stay on the actor that owns playback.
    isolated deinit {}

    /// Install item state before loading the engine. New intents start with fresh configuration.
    func configure(for intent: PlaybackIntent) {
        playbackIntent = intent
        configuration = intent.itemConfiguration ?? Configuration()

        if let defaults = configuration.automaticTrackDefaults {
            automaticTrackDefaults = defaults
        }

        configuration.automaticTrackDefaults = automaticTrackDefaults
    }

    /// Begin observations after the mediaSession has completed installation.
    func activate() {
        guard let mediaSession, mediaSession.playbackItem === self else { return }

        if baseItem.mediaType != .audio {
            let segments = MediaSegmentObserver()
            self.segments = segments
            segmentObservation = segments.observe(mediaSession)
        }

        if baseItem.mediaType != .audio, !subtitleStreams.isEmpty {
            replaySubtitles = MediaPlayerItemReplaySubtitles(item: self, events: mediaSession.playbackEvents)
        }

        let preferences = MediaPlayerItemPreferences(item: self)
        mediaPreferences = preferences
        preferences.start()
    }

    func resumingIntent(at position: Duration) -> PlaybackIntent? {
        playbackIntent?.updating(
            startSeconds: position,
            audioStreamIndex: selectedAudioStreamIndex,
            subtitleStreamIndex: selectedSubtitleStreamIndex,
            secondarySubtitleStreamIndex: selectedSecondarySubtitleStreamIndex,
            preservingTrackPreferences: true
        )
        .preserving(configuration: configuration)
    }

    var canSelectTracks: Bool {
        mediaSession?.playbackItem === self && mediaSession?.canControlPlayback == true
    }

    /// Decides whether a track change can be performed by the player in place, or whether the server must produce a new stream.
    func isRebuildRequired(type: MediaStreamType, from oldIndex: Int?, to newIndex: Int?) -> Bool {
        guard oldIndex != newIndex else { return false }

        let isTranscoding = mediaSource.transcodingURL != nil

        // Removing a burned-in subtitle needs a new stream too.
        if type == .subtitle, isTranscoding,
           subtitleStreams.first(where: { $0.index == oldIndex })?.deliveryMethod == .encode
        {
            return true
        }

        guard let newIndex, newIndex != -1 else { return false }

        switch type {
        case .audio:
            if isTranscoding {
                return true
            }

            guard let newStream = audioStreams.first(where: { $0.index == newIndex }) else { return true }

            return !deviceProfile.canPlay(
                type: baseItem.mediaType == .audio ? .audio : .video,
                audioCodec: newStream.codec,
                container: mediaSource.container
            )

        case .subtitle:
            guard let newStream = subtitleStreams.first(where: { $0.index == newIndex }) else { return false }

            // Honor the negotiated delivery, including extracted/converted embedded subtitles.
            // Their original codec and `isExternal` flag do not describe the sidecar file.
            switch newStream.deliveryMethod {
            case .encode:
                return true
            case .external:
                return !newStream.isSidecarSubtitle
            case .hls:
                return indexMap.playerIndex(for: newIndex) == nil
            case .drop:
                return false
            case .embed, nil:
                break
            }

            if newStream.isExternal == true {

                // External subtitles can only be loaded as sidecars when the profile allows external or HLS delivery for the format.
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

    func switchTrack(type: MediaStreamType, index: Int?) {
        guard let player = mediaSession?.player as? any MediaPlayerTrackProviding else { return }

        let playerIndex = indexMap.playerIndex(for: index)

        switch type {
        case .audio:
            guard let playerIndex else { return }

            player.setStream(.init(index: playerIndex, type: .audio))

        case .subtitle:
            // Disable subtitles until the requested track is available.
            player.setStream(.init(index: playerIndex ?? -1, type: .subtitle))

        default:
            return
        }
    }

    /// Replaces estimated track indexes with those reported by the player.
    func setTrackIndexes(_ indexMap: MediaTrackIndexMap) {
        self.indexMap = indexMap
        switchTrack(type: .audio, index: selectedAudioStreamIndex)
        applySelectedSubtitleTracks()
    }
}
