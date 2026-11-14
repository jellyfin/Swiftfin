//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import MPVUI

extension MediaTrackIndexMap {

    /// FFmpeg indexes match the original representation. Transcodes are mapped only to the requested audio stream.
    static func mpv(
        mediaStreams: [MediaStream],
        tracks: [MPVMediaTrack],
        isTranscoding: Bool,
        selectedAudioStreamIndex: Int?
    ) -> MediaTrackIndexMap {
        var map = MediaTrackIndexMap()

        let externalIndexes = mediaStreams.filter { $0.isExternal == true }.compactMap(\.index)

        for (streamType, trackType) in [(MediaStreamType.audio, MPVTrackType.audio), (.subtitle, .subtitle)] {
            let streams = mediaStreams.filter { $0.type == streamType && $0.isExternal != true && !$0.isSidecarSubtitle }
            let internalTracks = tracks.filter { $0.type == trackType && !$0.isExternal }

            if isTranscoding {
                if streamType == .audio, let index = selectedAudioStreamIndex, let track = internalTracks.first {
                    map.setPlayerIndex(track.mpvID, for: index)
                }

                continue
            }

            var remaining = internalTracks

            for stream in streams {
                guard let index = stream.index else {
                    continue
                }

                let sourceIndex = index - externalIndexes.count(where: { $0 < index })
                let exact = remaining.filter { $0.sourceStreamIndex == sourceIndex }
                let matches = exact.isEmpty ? remaining.filter { track in
                    guard track.sourceStreamIndex == nil else {
                        return false
                    }

                    if let codec = stream.codec,
                       let native = track.codec,
                       MPVTrackIdentity.codecName(codec) != MPVTrackIdentity.codecName(native) {
                        return false
                    }

                    if let language = stream.language, let native = track.language, language != native {
                        return false
                    }

                    if let title = stream.title, let native = track.title, title != native {
                        return false
                    }

                    if stream.isHearingImpaired == true && !track.isHearingImpaired {
                        return false
                    }

                    return true
                } : exact

                guard matches.count == 1, let track = matches.first else {
                    continue
                }

                map.setPlayerIndex(track.mpvID, for: index)
                remaining.removeAll { $0.id == track.id }
            }
        }

        for stream in mediaStreams.sidecarSubtitles {
            if let index = stream.index,
               let track = tracks
                .first(where: { $0.type == .subtitle && $0.isExternal && $0.clientID == MPVTrackIdentity.subtitleID(index) }) {
                map.setPlayerIndex(track.mpvID, for: index)
            }
        }

        return map
    }
}
