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

/// Optional caption behavior driven by transport events, independent of the mediaSession's state machine.
@MainActor
final class MediaPlayerItemReplaySubtitles {

    private weak var item: MediaPlayerItem?
    private var observation: AnyCancellable?
    private var seek: (id: UUID, origin: Duration)?
    private var window: SkipBackSubtitles?
    private let isEnabled: () -> Bool

    var hasPendingSeek: Bool {
        seek != nil
    }

    init(
        item: MediaPlayerItem,
        events: AnyPublisher<MediaSession.PlaybackEvent, Never>,
        isEnabled: @escaping () -> Bool = { CaptionPreferences.showOnSkipBack == true }
    ) {
        self.item = item
        self.isEnabled = isEnabled

        observation = events.sink { [weak self] event in
            self?.receive(event)
        }
    }

    isolated deinit {}

    private func receive(_ event: MediaSession.PlaybackEvent) {
        switch event {
        case .positionChanged:
            refresh()

        case let .seekRequested(request, origin):
            if request.target < origin, isEnabled() {
                seek = (request.id, max(origin, max(seek?.origin ?? origin, window?.end ?? origin)))
            } else {
                end()
            }

        case let .seekCompleted(request, position, hasPendingSeek):
            if seek?.id == request.id {
                let origin = seek?.origin
                seek = nil

                if let position, let origin, !hasPendingSeek, position < origin {
                    begin(from: origin, at: position)
                }
            }

            refresh()
        }
    }

    private func begin(from origin: Duration, at position: Duration) {
        guard isEnabled(), let item,
              !item.subtitlesEnabled || item.isShowingSubtitlesOnSkipBack,
              let provider = item.mediaSession?.player as? MediaPlayerSubtitleCueProviding else { return }

        func isAvailable(_ index: Int) -> Bool {
            guard index >= 0, let playerIndex = item.indexMap.playerIndex(for: index),
                  !item.isRebuildRequired(type: .subtitle, from: -1, to: index) else { return false }

            return provider.canObserveSubtitleCues(at: playerIndex)
        }

        var tracks = SubtitleTrackSelection(
            primary: item.configuration.disabledSubtitleTracks != nil || item.isShowingSubtitlesOnSkipBack
                ? item.subtitleTrackIndex(secondary: false) : -1,
            secondary: item.subtitleTrackIndex(secondary: true)
        )

        if !isAvailable(tracks.primary) {
            tracks.primary = -1
        }

        if !isAvailable(tracks.secondary) {
            tracks.secondary = -1
        }

        if tracks.primary < 0, tracks.secondary < 0 {
            let streams = item.subtitleStreams.filter { isAvailable($0.index ?? -1) }

            tracks.primary = MediaPlaybackPreferences.current.subtitleForReplay(
                in: streams, defaultIndex: item.mediaSource.defaultSubtitleStreamIndex
            ) ?? -1
        }

        guard tracks.primary >= 0 || tracks.secondary >= 0 else { return }

        window = SkipBackSubtitles(from: origin, to: position)
        item.setTemporarySubtitleTracks(tracks)
    }

    func end(apply: Bool = true) {
        seek = nil
        window = nil

        if item?.temporarySubtitleTracks != nil {
            item?.setTemporarySubtitleTracks(nil, apply: apply)
        }
    }

    /// Called by both transport updates and the loaded item's engine cue callbacks.
    func refresh() {
        guard var window else { return }
        guard isEnabled() else {
            end()
            return
        }
        guard let mediaSession = item?.mediaSession, !mediaSession.isSeeking,
              let provider = mediaSession.player as? MediaPlayerSubtitleCueProviding else { return }

        if window.hasFinished(at: mediaSession.observedSeconds, cues: provider.subtitleCues) {
            end()
        } else {
            self.window = window
        }
    }
}
