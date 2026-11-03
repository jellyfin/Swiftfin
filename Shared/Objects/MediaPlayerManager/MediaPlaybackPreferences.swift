//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import MediaAccessibility
import MediaAccessibilityKit

/// System accessibility preferences augment server defaults, but explicit track choices always take precedence.
struct MediaPlaybackPreferences {

    var captions: CaptionPreferences
    var audio: AudibleMediaPreferences
    var languages: [String] = Locale.preferredLanguages

    static var current: Self {
        Self(captions: .current, audio: .current)
    }

    struct Selection: Equatable {

        var audio: Int?
        var subtitle: Int?
    }

    func selection(in source: MediaSourceInfo, audio explicitAudio: Int? = nil, subtitle explicitSubtitle: Int? = nil) -> Selection {
        let streams = source.mediaStreams ?? []
        let audioStreams = streams.filter { $0.type == .audio && $0.isExternal != true && ($0.index ?? -1) >= 0 }
        let subtitles = streams.filter { $0.type == .subtitle && $0.deliveryMethod != .drop && ($0.index ?? -1) >= 0 }
        let defaultAudio = audioStreams.first(property: \.index, equalTo: source.defaultAudioStreamIndex)

        // Wait for the server's language choice when its default audio index is not available yet.
        let preferredAudio = defaultAudio.flatMap { preferredAudio(in: audioStreams, default: $0) }
        let audioIndex = explicitAudio ?? preferredAudio?.index ?? source.defaultAudioStreamIndex
        let audioLanguage = audioStreams.first(property: \.index, equalTo: audioIndex)?.language

        return Selection(
            audio: audioIndex,
            subtitle: explicitSubtitle ?? preferredSubtitle(
                in: subtitles, defaultIndex: source.defaultSubtitleStreamIndex, audioLanguage: audioLanguage
            )
        )
    }

    private func preferredAudio(in streams: [MediaStream], default fallback: MediaStream?) -> MediaStream? {
        guard audio.preferredCharacteristics.contains(MAMediaCharacteristicDescribesVideoForAccessibility as String) else {
            return nil
        }

        let preferredLanguages = fallback?.language.map { [$0] } ?? languages
        let candidates = streams.filter { $0.hasAudioDescriptionLabel && languageRank($0.language, in: preferredLanguages) != nil }

        return best(in: candidates, languages: preferredLanguages, defaultIndex: fallback?.index)
    }

    func subtitleForReplay(in streams: [MediaStream], defaultIndex: Int?) -> Int? {
        let fullCaptions = streams.filter { $0.isForced != true }

        return best(
            in: fullCaptions.isEmpty ? streams : fullCaptions,
            languages: captions.selectedLanguages.isEmpty ? languages : captions.selectedLanguages,
            defaultIndex: defaultIndex
        )?.index
    }

    private func preferredSubtitle(in streams: [MediaStream], defaultIndex: Int?, audioLanguage: String?) -> Int? {
        // Missing stream metadata can be filled by the playback-info response. Leave negotiation to the server.
        guard streams.isNotEmpty else { return defaultIndex }

        let preferredLanguages = captions.selectedLanguages.isEmpty ? languages : captions.selectedLanguages
        let forced = streams.filter { $0.isForced == true }
        let forcedLanguages = audioLanguage.map { [$0] } ?? preferredLanguages

        let forcedIndex = best(
            in: forced.filter { languageRank($0.language, in: forcedLanguages) != nil },
            languages: forcedLanguages, defaultIndex: defaultIndex
        )?.index ?? -1

        switch captions.displayType {
        case .forcedOnly:
            return forcedIndex

        case .alwaysOn:
            return best(in: streams.filter { $0.isForced != true }, languages: preferredLanguages, defaultIndex: defaultIndex)?.index
                ?? forcedIndex

        case .automatic:
            // Honor the account's subtitle mode and remembered selections when it provides a track.
            if let defaultIndex, streams.contains(where: { $0.index == defaultIndex }) {
                return defaultIndex
            }

            guard let audioLanguage, let primaryLanguage = preferredLanguages.first,
                  let audioCode = languageCode(audioLanguage), let preferredCode = languageCode(primaryLanguage)
            else { return defaultIndex }
            guard audioCode != preferredCode else { return forcedIndex }

            let candidates = streams.filter { $0.isForced != true && languageRank($0.language, in: preferredLanguages) != nil }
            return best(in: candidates, languages: preferredLanguages, defaultIndex: defaultIndex)?.index ?? forcedIndex

        case .unknown:
            return defaultIndex
        }
    }

    private func best(in streams: [MediaStream], languages: [String], defaultIndex: Int?) -> MediaStream? {
        let prefersSDH = captions.displayType == .alwaysOn || captions.preferredCharacteristics.contains {
            $0 == MAMediaCharacteristicTranscribesSpokenDialogForAccessibility as String
                || $0 == MAMediaCharacteristicDescribesMusicAndSoundForAccessibility as String
        }

        return streams.enumerated()
            .min { lhs, rhs in
                func rank(_ stream: MediaStream, offset: Int) -> [Int] {
                    [
                        languageRank(stream.language, in: languages) ?? Int.max,
                        prefersSDH && stream.type == .subtitle && stream.isHearingImpaired == true ? 0 : 1,
                        stream.index == defaultIndex ? 0 : 1,
                        stream.isDefault == true ? 0 : 1,
                        offset
                    ]
                }

                return rank(lhs.element, offset: lhs.offset).lexicographicallyPrecedes(rank(rhs.element, offset: rhs.offset))
            }?.element
    }

    private func languageRank(_ language: String?, in preferences: [String]) -> Int? {
        guard let language, let code = languageCode(language) else { return nil }

        for (index, preference) in preferences.enumerated() {
            if Locale.canonicalLanguageIdentifier(from: language) == Locale.canonicalLanguageIdentifier(from: preference) {
                return index * 2
            }

            if code == languageCode(preference) {
                return index * 2 + 1
            }
        }

        return nil
    }

    private func languageCode(_ identifier: String) -> String? {
        let code = Locale.Language(identifier: identifier).languageCode
        guard let code, code.identifier != "und", code.identifier != "zxx" else { return nil }

        // Jellyfin uses ISO 639-2 codes while Apple normally supplies BCP-47 identifiers.
        return code.identifier(.alpha2) ?? code.identifier(.alpha3)
    }
}

extension MediaStream {

    /// The SDK has no audio-description disposition. Use explicit metadata labels, never commentary or hearing-impaired flags.
    var hasAudioDescriptionLabel: Bool {
        [title, displayTitle].compactMap(\.self).contains {
            $0.range(
                of: #"\b(audio[ -]?description[s]?|audio[ -]?described|descriptive[ -]?audio|described[ -]?video)\b|(?:^|[\[(]| - )(?:AD|DVS)(?:$|[\])]| - )"#,
                options: [.regularExpression, .caseInsensitive]
            ) != nil
        }
    }
}
