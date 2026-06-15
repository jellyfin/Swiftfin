//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

// TODO: may need some changes for AVPlayer

struct MediaTrackIndexMap {

    private var playerIndexesByJellyfinIndex: [Int: Int]

    init(_ playerIndexesByJellyfinIndex: [Int: Int] = [:]) {
        self.playerIndexesByJellyfinIndex = playerIndexesByJellyfinIndex
    }

    func playerIndex(for jellyfinIndex: Int?) -> Int? {
        guard let jellyfinIndex, jellyfinIndex != -1 else { return -1 }
        return playerIndexesByJellyfinIndex[jellyfinIndex]
    }

    mutating func setPlayerIndex(_ playerIndex: Int, for jellyfinIndex: Int) {
        playerIndexesByJellyfinIndex[jellyfinIndex] = playerIndex
    }

    /// Builds a mapping from Jellyfin's global stream indexes to VLC's container-position indexes.
    ///
    /// Jellyfin assigns a single global index across all streams (video, audio, subtitle — internal and external).
    /// VLC numbers tracks by their position within the actual media container, starting at 0.
    ///
    /// Called at init time — before VLC has loaded the media. Sidecar subtitle indexes are estimated here
    /// but finalized later by `resolvingPlaybackChildren` once the player reports its actual track list.
    ///
    ///  - `Transcode`: The HLS container has exactly 1 video (index 0) and 1 audio (index 1).
    ///  - `DirectPlay`: Jellyfin lists external tracks first, offsetting all internal container indexes by that count.
    static func build(
        from mediaStreams: [MediaStream],
        for playMethod: PlayMethod,
        selectedAudioStreamIndex: Int
    ) -> MediaTrackIndexMap {
        var indexMap = MediaTrackIndexMap()

        if playMethod == .transcode {
            var containerTracks: [MediaStream] = []

            let videoTracks = mediaStreams.filter { $0.type == .video && !($0.isExternal == true) }
            let audioTracks = mediaStreams.filter { $0.type == .audio && !($0.isExternal == true) }

            if let firstVideo = videoTracks.first {
                containerTracks.append(firstVideo)
            }
            if let selectedAudio = audioTracks.first(where: { $0.index == selectedAudioStreamIndex }) {
                containerTracks.append(selectedAudio)
            }

            for (newIndex, track) in containerTracks.enumerated() {
                guard let oldIndex = track.index else { continue }
                indexMap.setPlayerIndex(newIndex, for: oldIndex)
            }

            let playbackChildStartIndex = containerTracks.count
            let sidecarSubtitles = mediaStreams.sidecarSubtitles

            for (offset, track) in sidecarSubtitles.enumerated() {
                guard let oldIndex = track.index else { continue }
                let playerIndex = playbackChildStartIndex + offset
                indexMap.setPlayerIndex(playerIndex, for: oldIndex)
            }
        } else {
            let externalCount = mediaStreams.count(where: { $0.isExternal == true })
            let internalTracks = mediaStreams.filter { $0.isExternal == false }

            for track in internalTracks {
                guard let oldIndex = track.index else { continue }
                let playerIndex = oldIndex - externalCount
                indexMap.setPlayerIndex(playerIndex, for: oldIndex)
            }
        }

        return indexMap
    }

    /// Updates the index map with real player indexes for sidecar subtitles.
    ///
    /// Called after VLC reports its actual track list. Sidecar subtitles are loaded as "playback children"
    /// at runtime, so their player-assigned indexes aren't known until the player is running.
    ///
    ///  - `Transcode`: HLS has no embedded subtitles, so all reported subtitle tracks are sidecars — matched sequentially.
    ///  - `DirectPlay`: Container subtitles are already mapped. The remaining unmapped tracks are sidecars.
    func resolvingPlaybackChildren(
        _ playbackChildren: [MediaStream],
        subtitleTracks: [(index: Int, title: String)],
        isTranscoding: Bool
    ) -> MediaTrackIndexMap {
        guard playbackChildren.isNotEmpty else { return self }

        var updatedMap = self

        let playerIndexes = subtitleTracks
            .map(\.index)
            .filter { $0 >= 0 }
            .sorted()

        if isTranscoding {
            for (offset, playerIndex) in playerIndexes.enumerated() {
                guard offset < playbackChildren.count,
                      let jellyfinIndex = playbackChildren[offset].index
                else { continue }

                updatedMap.setPlayerIndex(playerIndex, for: jellyfinIndex)
            }
        } else {
            let mappedIndexes = Set(playerIndexesByJellyfinIndex.values)
            let unmappedIndexes = playerIndexes
                .filter { !mappedIndexes.contains($0) }

            let externalIndexes: [Int] = Array(unmappedIndexes.suffix(playbackChildren.count))

            for (offset, stream) in playbackChildren.enumerated() {
                guard let jellyfinIndex = stream.index else { continue }

                if offset < externalIndexes.count {
                    updatedMap.setPlayerIndex(externalIndexes[offset], for: jellyfinIndex)
                }
            }
        }

        return updatedMap
    }
}
