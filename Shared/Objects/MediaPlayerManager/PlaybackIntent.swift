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

@MainActor
struct PlaybackIntent {

    private(set) var itemConfiguration: MediaPlayerItem.Configuration?
    private let entry: ItemEntry
    private(set) var mediaSource: MediaSourceInfo?
    private(set) var audioStreamIndex: Int?
    private(set) var subtitleStreamIndex: Int?
    private(set) var secondarySubtitleStreamIndex: Int?
    private(set) var followsSystemAudioPreferences: Bool
    private(set) var followsSystemCaptionPreferences: Bool
    private(set) var requestedBitrate: PlaybackBitrate
    let compatibilityMode: PlaybackCompatibility
    private(set) var startSeconds: Duration?
    private let resumeOffset: Duration

    var item: BaseItemDto {
        entry.snapshot
    }

    init(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo? = nil,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        secondarySubtitleStreamIndex: Int? = nil,
        requestedBitrate: PlaybackBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate],
        compatibilityMode: PlaybackCompatibility = Defaults[.VideoPlayer.Playback.compatibilityMode]
    ) {
        self.entry = SharedBaseItem(wrappedValue: item).entry
        self.mediaSource = mediaSource ?? item.mediaSources?.first
        self.audioStreamIndex = audioStreamIndex
        self.subtitleStreamIndex = subtitleStreamIndex
        self.secondarySubtitleStreamIndex = secondarySubtitleStreamIndex
        self.followsSystemAudioPreferences = audioStreamIndex == nil
        self.followsSystemCaptionPreferences = subtitleStreamIndex == nil && secondarySubtitleStreamIndex == nil
        self.requestedBitrate = requestedBitrate
        self.compatibilityMode = compatibilityMode
        self.startSeconds = nil
        self.resumeOffset = .seconds(Defaults[.VideoPlayer.resumeOffset])
    }

    func updating(
        startSeconds: Duration? = nil,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        secondarySubtitleStreamIndex: Int? = nil,
        requestedBitrate: PlaybackBitrate? = nil,
        preservingTrackPreferences: Bool = false
    ) -> Self {
        with(self) {
            if let startSeconds {
                $0.startSeconds = max(.zero, startSeconds)
            }

            if let audioStreamIndex {
                $0.audioStreamIndex = audioStreamIndex

                if !preservingTrackPreferences {
                    $0.followsSystemAudioPreferences = false
                }
            }

            if let subtitleStreamIndex {
                $0.subtitleStreamIndex = subtitleStreamIndex

                if !preservingTrackPreferences {
                    $0.followsSystemCaptionPreferences = false
                }
            }

            if let secondarySubtitleStreamIndex {
                $0.secondarySubtitleStreamIndex = secondarySubtitleStreamIndex

                if !preservingTrackPreferences {
                    $0.followsSystemCaptionPreferences = false
                }
            }

            if let requestedBitrate {
                $0.requestedBitrate = requestedBitrate
            }
        }
    }

    /// Only rebuilds and retries carry resolved item state. A new item or source starts fresh.
    func preserving(configuration: MediaPlayerItem.Configuration) -> Self {
        with(self) { $0.itemConfiguration = configuration }
    }

    func followingSystemPreferences(audio: Bool = false, subtitles: Bool = false) -> Self {
        with(self) {
            if audio {
                $0.followsSystemAudioPreferences = true
            }

            if subtitles {
                $0.followsSystemCaptionPreferences = true
            }
        }
    }

    func selecting(mediaSource: MediaSourceInfo?) -> Self {
        with(self) {
            $0.itemConfiguration = nil
            $0.mediaSource = mediaSource
            $0.audioStreamIndex = nil
            $0.subtitleStreamIndex = nil
            $0.secondarySubtitleStreamIndex = nil
            $0.followsSystemAudioPreferences = true
            $0.followsSystemCaptionPreferences = true
        }
    }

    func resolve(for playerType: MediaPlayerType, userSession: UserSession) async throws -> MediaPlayerItem {
        try Task.checkCancellation()

        guard var item = entry.value else { throw ItemStore.StoreError.itemUnavailable }

        if item.type == .program {
            guard let channel = try await item.getChannel(for: item, userSession: userSession) else {
                throw ErrorMessage(L10n.unknownError)
            }

            item = channel
        }

        let resolved = try await MediaPlayerItem.build(
            for: item,
            userSession: userSession,
            mediaSource: mediaSource,
            audioStreamIndex: audioStreamIndex,
            subtitleStreamIndex: subtitleStreamIndex,
            secondarySubtitleStreamIndex: playerType == .mpv ? secondarySubtitleStreamIndex : nil,
            mediaPlayerType: playerType,
            requestedBitrate: requestedBitrate,
            compatibilityMode: compatibilityMode,
            modifyItem: applyOverrides
        )

        guard entry.value != nil else {
            await MediaProgressReporter.discard(resolved, session: userSession)
            throw ItemStore.StoreError.itemUnavailable
        }

        return resolved
    }

    private func applyOverrides(to item: inout BaseItemDto) {
        let position = startSeconds ?? max(.zero, (item.startSeconds ?? .zero) - resumeOffset)
        var userData = item.userData ?? UserItemDataDto(key: item.id ?? "")

        userData.playbackPositionTicks = position.ticks
        item.userData = userData
    }
}
