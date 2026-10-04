//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CryptoKit
import Foundation
import JellyfinAPI

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

    /// Maps Jellyfin stream indexes to positions in each player track array.
    /// Embedded tracks keep their order; transcoding exposes only the selected audio track.
    /// Sidecar subtitles are resolved after loading.
    static func build(
        from mediaStreams: [MediaStream],
        for playMethod: PlayMethod,
        selectedAudioStreamIndex: Int
    ) -> MediaTrackIndexMap {
        var indexMap = MediaTrackIndexMap()

        if playMethod == .transcode {
            let audioStreams = mediaStreams.filter { $0.type == .audio && $0.isExternal != true }

            if let jellyfinIndex = audioStreams.first(where: { $0.index == selectedAudioStreamIndex })?.index {
                indexMap.setPlayerIndex(0, for: jellyfinIndex)
            }
        } else {
            let embeddedAudioStreams = mediaStreams.filter { $0.type == .audio && $0.isExternal != true }
            let embeddedSubtitleStreams = mediaStreams.filter { $0.type == .subtitle && $0.isExternal != true }

            for (playerIndex, stream) in embeddedAudioStreams.enumerated() {
                guard let jellyfinIndex = stream.index else { continue }
                indexMap.setPlayerIndex(playerIndex, for: jellyfinIndex)
            }

            for (playerIndex, stream) in embeddedSubtitleStreams.enumerated() {
                guard let jellyfinIndex = stream.index else { continue }
                indexMap.setPlayerIndex(playerIndex, for: jellyfinIndex)
            }
        }

        return indexMap
    }

    /// Maps each sidecar to its loaded subtitle track.
    func resolvingSidecarSubtitles(
        _ sidecars: [(jellyfinIndex: Int, url: URL)],
        subtitleTracks: [(playerIndex: Int, id: String)]
    ) -> MediaTrackIndexMap {
        var resolvedMap = self

        for subtitle in sidecars {
            // Match libVLC's MD5(full URL)/spu/... track IDs in SwiftVLC 1.0.0.
            // https://github.com/videolan/vlc/blob/c833c4be0/src/input/input.c#L2742-L2765
            let urlHash = Insecure.MD5.hash(data: Data(subtitle.url.absoluteString.utf8))
                .map { String(format: "%02x", $0) }.joined()
            resolvedMap.playerIndexesByJellyfinIndex[subtitle.jellyfinIndex] = subtitleTracks.first {
                $0.playerIndex >= 0 && $0.id.hasPrefix("\(urlHash)/spu/")
            }?.playerIndex
        }

        return resolvedMap
    }
}
