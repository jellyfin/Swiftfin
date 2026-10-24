//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension MediaPlayerItem {

    var selectedAudioStreamIndex: Int? {
        get {
            configuration.audioStreamIndex
        }
        set {
            selectTracks(audio: newValue)
        }
    }

    var selectedSubtitleStreamIndex: Int? {
        get {
            configuration.subtitleStreamIndex
        }
        set {
            selectTracks(subtitle: newValue ?? -1)
        }
    }

    var selectedSecondarySubtitleStreamIndex: Int? {
        configuration.secondarySubtitleStreamIndex
    }

    var audioOffset: Duration {
        get {
            configuration.audioOffset
        }
        set {
            configuration.audioOffset = newValue
            (mediaSession?.player as? MediaPlayerOffsetProviding)?.setOffset(newValue, for: .audio)
        }
    }

    var subtitleOffset: Duration {
        get {
            configuration.subtitleOffset
        }
        set {
            configuration.subtitleOffset = newValue
            (mediaSession?.player as? MediaPlayerOffsetProviding)?.setOffset(newValue, for: .subtitle)
        }
    }

    var secondarySubtitleOffset: Duration {
        get {
            configuration.secondarySubtitleOffset
        }
        set {
            configuration.secondarySubtitleOffset = newValue
            (mediaSession?.player as? MediaPlayerSecondarySubtitleProviding)?.setSecondarySubtitleOffset(newValue)
        }
    }

    func applyPlaybackOffsets() {
        if let provider = mediaSession?.player as? MediaPlayerOffsetProviding {
            provider.setOffset(audioOffset, for: .audio)
            provider.setOffset(subtitleOffset, for: .subtitle)
        }

        (mediaSession?.player as? MediaPlayerSecondarySubtitleProviding)?.setSecondarySubtitleOffset(secondarySubtitleOffset)
    }

    func selectTracks(
        audio: Int? = nil,
        subtitle: Int? = nil,
        secondary: Int? = nil,
        preservingTrackPreferences: Bool = false
    ) {
        guard canSelectTracks else { return }
        guard audio == nil || audioStreams.contains(where: { $0.index == audio }),
              subtitle == nil || subtitle == -1 || subtitleStreams.contains(where: { $0.index == subtitle }),
              secondary == nil || secondary == -1
              || (supportsSecondarySubtitles && secondarySubtitleStreams.contains(where: { $0.index == secondary }))
        else { return }

        let newAudio = audio ?? configuration.audioStreamIndex
        let newSubtitle = subtitle ?? configuration.subtitleStreamIndex ?? -1

        let needsRebuild = isRebuildRequired(type: .audio, from: configuration.audioStreamIndex, to: newAudio)
            || isRebuildRequired(type: .subtitle, from: configuration.subtitleStreamIndex, to: newSubtitle)

        if subtitle != nil || secondary != nil {
            replaySubtitles?.end(apply: false)
        }

        configuration.selectTracks(
            audio: audio,
            subtitle: subtitle,
            secondary: secondary,
            preservingPreferences: preservingTrackPreferences
        )

        if needsRebuild {
            mediaSession?.reload(self)
        } else {
            if audio != nil {
                switchTrack(type: .audio, index: newAudio)
            }

            if subtitle != nil || secondary != nil {
                setTemporarySubtitleTracks(nil)
            }

            if audio != nil, !preservingTrackPreferences {
                mediaPreferences?.apply()
            }
        }
    }

    var supportsSecondarySubtitles: Bool {
        mediaSession?.player is MediaPlayerSecondarySubtitleProviding
    }

    var isShowingSubtitlesOnSkipBack: Bool {
        temporarySubtitleTracks != nil
    }

    var subtitlesEnabled: Bool {
        effectiveSubtitleStreamIndex >= 0 || effectiveSecondarySubtitleStreamIndex >= 0
    }

    func subtitleTrackIndex(secondary: Bool) -> Int {
        let index: Int = if subtitlesEnabled {
            secondary ? effectiveSecondarySubtitleStreamIndex : effectiveSubtitleStreamIndex
        } else if let disabled = configuration.disabledSubtitleTracks {
            secondary ? disabled.secondary : disabled.primary
        } else {
            secondary ? -1 : defaultSubtitleTrackIndex
        }

        let streams = secondary ? secondarySubtitleStreams : subtitleStreams
        guard streams.contains(where: { $0.index == index }),
              !secondary || (supportsSecondarySubtitles && index != subtitleTrackIndex(secondary: false))
        else { return -1 }

        return index
    }

    private var defaultSubtitleTrackIndex: Int {
        if let index = mediaSource.defaultSubtitleStreamIndex, index >= 0,
           subtitleStreams.contains(where: { $0.index == index })
        {
            return index
        }

        return subtitleStreams.first { ($0.index ?? -1) >= 0 }?.index ?? -1
    }

    func setSubtitleTrack(index: Int, secondary: Bool) {
        guard canSelectTracks else { return }

        var primaryIndex = subtitleTrackIndex(secondary: false)
        var secondaryIndex = subtitleTrackIndex(secondary: true)
        let wasEnabled = subtitlesEnabled

        if secondary {
            guard supportsSecondarySubtitles,
                  index == -1 || (index != primaryIndex && secondarySubtitleStreams.contains(where: { $0.index == index }))
            else { return }

            secondaryIndex = index
        } else {
            guard index == -1 || subtitleStreams.contains(where: { $0.index == index }) else { return }

            primaryIndex = index

            if secondaryIndex == index {
                secondaryIndex = -1
            }
        }

        replaySubtitles?.end(apply: false)
        configuration.selectTracks(subtitle: selectedSubtitleStreamIndex ?? -1)
        configuration.disabledSubtitleTracks = .init(primary: primaryIndex, secondary: secondaryIndex)

        if wasEnabled {
            selectTracks(subtitle: primaryIndex, secondary: secondaryIndex)
        }
    }

    func setSubtitlesEnabled(_ enabled: Bool) {
        guard canSelectTracks,
              enabled != subtitlesEnabled || isShowingSubtitlesOnSkipBack || replaySubtitles?.hasPendingSeek == true
        else { return }

        var primaryIndex = subtitleTrackIndex(secondary: false)
        let secondaryIndex = subtitleTrackIndex(secondary: true)
        replaySubtitles?.end(apply: false)

        if enabled {
            if primaryIndex < 0, secondaryIndex < 0 {
                primaryIndex = defaultSubtitleTrackIndex
            }

            selectTracks(subtitle: primaryIndex, secondary: secondaryIndex)
        } else {
            configuration.disabledSubtitleTracks = .init(primary: primaryIndex, secondary: secondaryIndex)
            selectTracks(subtitle: -1, secondary: -1)
        }
    }
}
