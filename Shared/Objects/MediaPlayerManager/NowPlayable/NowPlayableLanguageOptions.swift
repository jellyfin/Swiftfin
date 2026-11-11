//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import MediaPlayer

@MainActor
struct NowPlayableLanguageOptions {

    private enum Kind: String {

        case audio
        case subtitle
        case secondarySubtitle
    }

    private struct Selection {

        let option: MPNowPlayingInfoLanguageOption
        let kind: Kind
        let index: Int
    }

    private var selections: [Selection] = []
    private(set) var groups: [MPNowPlayingInfoLanguageOptionGroup] = []
    private(set) var current: [MPNowPlayingInfoLanguageOption] = []

    init(item: MediaPlayerItem? = nil) {
        guard let item, item.mediaSession?.player is MediaPlayerTrackProviding else { return }

        append(
            item.audioStreams,
            kind: .audio,
            selected: item.selectedAudioStreamIndex,
            defaultIndex: item.configuration.automaticTrackDefaults?.audio,
            item: item
        )

        append(
            item.subtitleStreams,
            kind: .subtitle,
            selected: item.effectiveSubtitleStreamIndex,
            defaultIndex: item.configuration.automaticTrackDefaults?.subtitle,
            item: item
        )

        if item.supportsSecondarySubtitles {
            append(
                item.secondarySubtitleStreams,
                kind: .secondarySubtitle,
                selected: item.effectiveSecondarySubtitleStreamIndex,
                defaultIndex: nil,
                item: item
            )
        }
    }

    private mutating func append(_ streams: [MediaStream], kind: Kind, selected: Int?, defaultIndex: Int?, item: MediaPlayerItem) {
        let options = streams.compactMap { stream -> Selection? in
            guard let index = stream.index, index >= 0 else { return nil }

            let type: MPNowPlayingInfoLanguageOptionType = kind == .audio ? .audible : .legible
            let language = stream.language.map { Locale.Language(identifier: $0).languageCode?.identifier(.alpha2) ?? $0 } ?? "und"
            var characteristics: [String] = []

            if stream.isDefault == true {
                characteristics.append(MPLanguageOptionCharacteristicIsMainProgramContent)
            }

            if stream.isForced == true {
                characteristics.append(MPLanguageOptionCharacteristicContainsOnlyForcedSubtitles)
            }

            if stream.isHearingImpaired == true, kind != .audio {
                characteristics += [
                    MPLanguageOptionCharacteristicTranscribesSpokenDialog,
                    MPLanguageOptionCharacteristicDescribesMusicAndSound
                ]
            }

            if kind == .audio, stream.hasAudioDescriptionLabel {
                characteristics.append(MPLanguageOptionCharacteristicDescribesVideo)
            }

            let name = stream.displayTitle ?? stream.title ?? stream.language ?? (kind == .audio ? L10n.audio : L10n.subtitles)
            let displayName = kind == .secondarySubtitle ? "\(L10n.secondarySubtitles) · \(name)" : name

            return Selection(
                option: .init(
                    type: type,
                    languageTag: language,
                    characteristics: characteristics,
                    displayName: displayName,
                    identifier: "\(item.playSessionID):\(kind.rawValue):\(index)"
                ),
                kind: kind,
                index: index
            )
        }

        guard options.isNotEmpty else { return }

        selections += options

        groups.append(.init(
            languageOptions: options.map(\.option),
            defaultLanguageOption: options.first(property: \.index, equalTo: defaultIndex)?.option,
            allowEmptySelection: kind != .audio
        ))

        if let option = options.first(property: \.index, equalTo: selected)?.option {
            current.append(option)
        }
    }

    func select(_ option: MPNowPlayingInfoLanguageOption, enabled: Bool, on item: MediaPlayerItem) -> Bool {
        guard item.canSelectTracks, item.mediaSession?.player is MediaPlayerTrackProviding else { return false }

        if enabled, option.isAutomaticAudibleLanguageOption() || option.isAutomaticLegibleLanguageOption() {
            let audible = option.isAutomaticAudibleLanguageOption()
            item.configuration.followSystemPreferences(audio: audible, subtitles: !audible)
            item.mediaPreferences?.update(.current)
            return true
        }

        if option.languageOptionType == .legible, option.languageTag == nil {
            item.setSubtitlesEnabled(false)
            return true
        }

        guard let selection = selections.first(where: {
            $0.option.identifier == option.identifier && $0.option.languageOptionType == option.languageOptionType
        }) else { return false }

        switch selection.kind {
        case .audio:
            guard enabled else { return false }

            item.selectTracks(audio: selection.index)

        case .subtitle:
            guard enabled || item.effectiveSubtitleStreamIndex == selection.index else { return false }

            item.selectTracks(subtitle: enabled ? selection.index : -1)

        case .secondarySubtitle:
            guard enabled || item.effectiveSecondarySubtitleStreamIndex == selection.index else { return false }

            item.selectTracks(secondary: enabled ? selection.index : -1)
        }

        return true
    }
}
