//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import MediaAccessibilityKit

/// Observes system preferences only for the lifetime of an attached item.
@MainActor
final class MediaPlayerItemPreferences {

    private weak var item: MediaPlayerItem?
    private var observations: Set<AnyCancellable> = []
    private var preferences = MediaPlaybackPreferences.current

    init(item: MediaPlayerItem) {
        self.item = item
    }

    isolated deinit {}

    func start() {
        Task { [weak self] in
            for await audio in AudibleMediaPreferences.updates {
                guard !Task.isCancelled, let self else { return }

                preferences.audio = audio
                apply()
            }
        }
        .asAnyCancellable()
        .store(in: &observations)

        if item?.baseItem.mediaType != .audio {
            Task { [weak self] in
                for await captions in CaptionPreferences.updates {
                    guard !Task.isCancelled, let self else { return }

                    preferences.captions = captions
                    apply()
                }
            }
            .asAnyCancellable()
            .store(in: &observations)
        }

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] _ in
                guard let self else { return }

                update(.current)
                item?.replaySubtitles?.refresh()
            }
            .store(in: &observations)

        let readiness = MediaPlayerObservation { [weak item] in
            item?.canSelectTracks == true
        } onChange: { [weak self] ready in
            if ready {
                self?.apply()
            }
        }

        // Initial delivery can replace the item synchronously.
        if item?.mediaPreferences === self {
            AnyCancellable(readiness).store(in: &observations)
        } else {
            readiness.cancel()
        }
    }

    func apply() {
        guard let item, item.canSelectTracks, let intent = item.playbackIntent else { return }

        // Negotiated responses can call the requested track their new default.
        // Keep the original baseline across replacements of the same item.
        var source = item.mediaSource
        source.defaultAudioStreamIndex = item.automaticTrackDefaults.audio
        source.defaultSubtitleStreamIndex = item.automaticTrackDefaults.subtitle

        let selection = preferences.selection(
            in: source,
            audio: intent.followsSystemAudioPreferences ? nil : item.selectedAudioStreamIndex,
            subtitle: intent.followsSystemCaptionPreferences ? nil : (item.selectedSubtitleStreamIndex ?? -1)
        )

        let audio = selection.audio ?? item.selectedAudioStreamIndex
        let subtitle = item.baseItem.mediaType == .audio ? item.selectedSubtitleStreamIndex
            : selection.subtitle ?? item.selectedSubtitleStreamIndex

        guard audio != item.selectedAudioStreamIndex || subtitle != item.selectedSubtitleStreamIndex else { return }

        item.replaySubtitles?.end()
        item.selectTracks(audio: audio, subtitle: subtitle, preservingTrackPreferences: true)
    }

    func update(_ preferences: MediaPlaybackPreferences) {
        self.preferences = preferences
        apply()
    }
}
