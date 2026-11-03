//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

/// The playback options carried from a request through resolution and the lifetime of its item.
@MainActor
struct MediaPlaybackConfiguration {

    private(set) var mediaSourceID: String?
    private(set) var audioStreamIndex: Int?
    private(set) var subtitleStreamIndex: Int?
    private(set) var secondarySubtitleStreamIndex: Int?
    private(set) var followsSystemAudioPreferences = true
    private(set) var followsSystemCaptionPreferences = true
    private(set) var automaticTrackDefaults: MediaPlaybackPreferences.Selection?

    var requestedBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate]
    var bitrateTestSize = Defaults[.VideoPlayer.Playback.appMaximumBitrateTest]
    var compatibilityMode = Defaults[.VideoPlayer.Playback.compatibilityMode]
    var maxResolution = Defaults[.VideoPlayer.Playback.appMaximumResolution]
    var forceSubtitleBurnIn = StoredValues[.User.forceSubtitleBurnIn]
    var forceHDRTranscode = StoredValues[.User.forceHDRTranscode]
    var forceDVTranscode = StoredValues[.User.forceDVTranscode]
    var customDeviceProfileAction = Defaults[.VideoPlayer.Playback.customDeviceProfileAction]
    var customDeviceProfiles = StoredValues[.User.customDeviceProfiles]
    var previewImageScrubbing = StoredValues[.User.previewImageScrubbing]
    var startSeconds: Duration?
    var resumeOffset: Duration = .seconds(Defaults[.VideoPlayer.resumeOffset])
    var audioOffset: Duration = .zero
    var subtitleOffset: Duration = .zero
    var secondarySubtitleOffset: Duration = .zero
    var disabledSubtitleTracks: SubtitleTrackSelection?
    var continuation: MediaPlaybackContinuation?

    init() {}

    func mediaSource(in item: BaseItemDto) -> MediaSourceInfo? {
        if let mediaSourceID {
            return item.mediaSources?.first { $0.id == mediaSourceID }
        }

        return item.mediaSources?.first
    }

    mutating func selectTracks(
        audio: Int? = nil,
        subtitle: Int? = nil,
        secondary: Int? = nil,
        preservingPreferences: Bool = false
    ) {
        if let audio {
            audioStreamIndex = audio
            if !preservingPreferences {
                followsSystemAudioPreferences = false
            }
        }

        if let subtitle {
            subtitleStreamIndex = subtitle

            if !preservingPreferences {
                followsSystemCaptionPreferences = false
            }
        }

        if let secondary {
            secondarySubtitleStreamIndex = secondary

            if !preservingPreferences {
                followsSystemCaptionPreferences = false
            }
        }

        if let subtitleStreamIndex, subtitleStreamIndex >= 0, secondarySubtitleStreamIndex == subtitleStreamIndex {
            secondarySubtitleStreamIndex = -1
        }
    }

    mutating func followSystemPreferences(audio: Bool = false, subtitles: Bool = false) {
        if audio {
            followsSystemAudioPreferences = true
        }

        if subtitles {
            followsSystemCaptionPreferences = true
        }
    }

    /// A different version has its own tracks, offsets, and server defaults.
    mutating func selectMediaSource(id: String?) {
        mediaSourceID = id
        audioStreamIndex = nil
        subtitleStreamIndex = nil
        secondarySubtitleStreamIndex = nil
        followsSystemAudioPreferences = true
        followsSystemCaptionPreferences = true
        automaticTrackDefaults = nil
        audioOffset = .zero
        subtitleOffset = .zero
        secondarySubtitleOffset = .zero
        disabledSubtitleTracks = nil
        continuation = nil
    }

    /// Resolve choices before the server negotiates audio and burned-in subtitles.
    mutating func prepare(
        for item: BaseItemDto,
        source: MediaSourceInfo,
        profile: PlaybackProfile,
        preferences: MediaPlaybackPreferences = .current
    ) {
        startSeconds = max(.zero, startSeconds ?? ((item.startSeconds ?? .zero) - resumeOffset))

        if let continued = continuation?.selection(for: item, in: source) {
            selectTracks(
                audio: audioStreamIndex == nil ? continued.audio : nil,
                subtitle: subtitleStreamIndex == nil ? continued.subtitle : nil
            )
        }

        continuation = nil

        let selection = preferences.selection(in: source, audio: audioStreamIndex, subtitle: subtitleStreamIndex)

        selectTracks(audio: selection.audio, subtitle: selection.subtitle, preservingPreferences: true)

        if !profile.supportsSecondarySubtitles {
            secondarySubtitleStreamIndex = -1
        }
    }

    mutating func finish(source: MediaSourceInfo, initialSource: MediaSourceInfo) {
        let audioStreams = source.mediaStreams?.filter { $0.type == .audio && $0.isExternal != true } ?? []

        if automaticTrackDefaults == nil {
            let initialAudioStreams = initialSource.mediaStreams?.filter { $0.type == .audio && $0.isExternal != true } ?? []
            let defaultAudio = initialSource.defaultAudioStreamIndex
                ?? (audioStreamIndex == nil ? source.defaultAudioStreamIndex : nil)
                ?? initialAudioStreams.first(where: { $0.isDefault == true })?.index
                ?? initialAudioStreams.first?.index
            automaticTrackDefaults = .init(
                audio: defaultAudio ?? source.defaultAudioStreamIndex
                    ?? audioStreams.first(where: { $0.isDefault == true })?.index ?? audioStreams.first?.index,
                subtitle: initialSource.defaultSubtitleStreamIndex
                    ?? (subtitleStreamIndex == nil ? source.defaultSubtitleStreamIndex : -1)
            )
        }

        // A live-stream response may have an ephemeral ID absent from the item's source list.
        // Keep the source we selected so retries can resolve it against fresh metadata.
        mediaSourceID = initialSource.id

        selectTracks(
            audio: audioStreamIndex ?? source.defaultAudioStreamIndex ?? audioStreams.first?.index ?? 0,
            subtitle: subtitleStreamIndex ?? source.defaultSubtitleStreamIndex ?? -1,
            secondary: secondarySubtitleStreamIndex ?? -1,
            preservingPreferences: true
        )
    }
}
