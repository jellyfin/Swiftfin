//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Snapshots persistent track choices at an item transition, before the old item is detached.
/// Stream indexes belong to one media source and must be matched again for the next episode.
struct MediaPlaybackContinuation {

    private let itemID: String
    private let seriesID: String
    private let audio: MediaStream?
    private let subtitle: MediaStream?
    private let subtitlesOff: Bool

    init?(
        item: BaseItemDto,
        source: MediaSourceInfo,
        audioStreamIndex: Int?,
        subtitleStreamIndex: Int?,
        configuration: UserConfiguration?
    ) {
        guard item.type == .episode,
              let itemID = item.id, !itemID.isEmpty,
              let seriesID = item.seriesID, !seriesID.isEmpty else { return nil }

        self.itemID = itemID
        self.seriesID = seriesID

        let streams = source.mediaStreams ?? []
        audio = configuration?.isRememberAudioSelections == true
            ? streams.first { $0.type == .audio && $0.index == audioStreamIndex && ($0.index ?? -1) >= 0 }
            : nil
        subtitle = configuration?.isRememberSubtitleSelections == true
            ? streams.first { $0.type == .subtitle && $0.index == subtitleStreamIndex && ($0.index ?? -1) >= 0 }
            : nil
        subtitlesOff = configuration?.isRememberSubtitleSelections == true && subtitleStreamIndex == -1

        guard audio != nil || subtitle != nil || subtitlesOff else { return nil }
    }

    func selection(for item: BaseItemDto, in source: MediaSourceInfo) -> (audio: Int?, subtitle: Int?) {
        guard item.type == .episode, item.id != itemID, item.seriesID == seriesID else { return (nil, nil) }

        return (
            audio.flatMap { match($0, in: source, defaultIndex: source.defaultAudioStreamIndex) },
            subtitlesOff ? -1 : subtitle.flatMap { match($0, in: source, defaultIndex: source.defaultSubtitleStreamIndex) }
        )
    }

    private func match(_ previous: MediaStream, in source: MediaSourceInfo, defaultIndex: Int?) -> Int? {
        let language = languageCode(previous.language)
        let candidates = (source.mediaStreams ?? []).filter { stream in
            guard stream.type == previous.type, let index = stream.index, index >= 0, stream.type != .audio || stream.isExternal != true,
                  stream.type != .subtitle || stream.deliveryMethod != .drop,
                  (stream.isForced == true) == (previous.isForced == true) else { return false }

            if let language {
                return languageCode(stream.language) == language
            }

            // Untagged tracks need a descriptive match. Reusing an index or codec alone can select another language.
            return languageCode(stream.language) == nil
                && (sameLabel(previous.title, stream.title) || sameLabel(previous.displayTitle, stream.displayTitle))
        }

        return candidates.enumerated()
            .min { lhs, rhs in
                func rank(_ stream: MediaStream, offset: Int) -> [Int] {
                    [
                        sameLabel(previous.title, stream.title) ? 0 : 1,
                        sameLabel(previous.displayTitle, stream.displayTitle) ? 0 : 1,
                        (previous.isHearingImpaired == true) == (stream.isHearingImpaired == true) ? 0 : 1,
                        sameLabel(previous.language, stream.language) ? 0 : 1,
                        previous.channels == stream.channels ? 0 : 1,
                        sameLabel(previous.codec, stream.codec) ? 0 : 1,
                        stream.index == defaultIndex ? 0 : 1,
                        stream.isDefault == true ? 0 : 1,
                        offset
                    ]
                }

                return rank(lhs.element, offset: lhs.offset).lexicographicallyPrecedes(rank(rhs.element, offset: rhs.offset))
            }?.element
            .index
    }

    private func sameLabel(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = lhs?.trimmingCharacters(in: .whitespacesAndNewlines), !lhs.isEmpty,
              let rhs = rhs?.trimmingCharacters(in: .whitespacesAndNewlines), !rhs.isEmpty else { return false }

        return lhs.caseInsensitiveCompare(rhs) == .orderedSame
    }

    private func languageCode(_ identifier: String?) -> String? {
        guard let identifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines), !identifier.isEmpty else { return nil }

        // Canonicalize ISO 639-2 bibliographic aliases (such as dut/nld) before asking for an alpha-2 code.
        let canonical = Locale.canonicalLanguageIdentifier(from: identifier)
        guard let code = Locale.Language(identifier: canonical).languageCode,
              code.identifier != "und", code.identifier != "zxx" else { return nil }

        return code.identifier(.alpha2) ?? code.identifier(.alpha3)
    }
}
