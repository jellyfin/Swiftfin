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
    private let isEnabled: () -> Bool

    private var observation: AnyCancellable?

    private var preparation: Task<Void, Never>?
    private var preparationOrigin: Duration?
    private var seek: (id: UUID, origin: Duration)?
    private var window: SkipBackSubtitles?

    var hasPendingSeek: Bool {
        seek != nil || preparation != nil
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

    isolated deinit {
        preparation?.cancel()
    }

    func end(apply: Bool = true) {
        preparation?.cancel()
        preparation = nil
        preparationOrigin = nil
        seek = nil
        window = nil

        if item?.temporarySubtitleTracks != nil {
            item?.setTemporarySubtitleTracks(nil, apply: apply)
        }
    }

    /// Called by both transport updates and the loaded item's engine cue callbacks.
    func refresh() {
        guard var window else {
            return
        }
        guard isEnabled() else {
            end()
            return
        }
        guard let mediaSession = item?.mediaSession,
              !mediaSession.isSeeking,
              let provider = mediaSession.player as? MediaPlayerSubtitleCueProviding
        else {
            return
        }

        if window.hasFinished(at: mediaSession.observedSeconds, cues: provider.subtitleCues) {
            end()
        } else {
            self.window = window
        }
    }

    private func receive(_ event: MediaSession.PlaybackEvent) {
        switch event {
        case .positionChanged:
            refresh()

        case let .seekRequested(request, origin):
            let previousOrigin = preparationOrigin

            preparation?.cancel()
            preparation = nil
            preparationOrigin = nil

            if request.target < origin, isEnabled() {
                seek = (request.id, max(origin, max(previousOrigin ?? origin, max(seek?.origin ?? origin, window?.end ?? origin))))
            } else {
                end()
            }

        case let .seekCompleted(request, position, hasPendingSeek):
            if seek?.id == request.id {
                let origin = seek?.origin
                seek = nil

                if let position, let origin, !hasPendingSeek, position < origin {
                    begin(from: origin)
                }
            }

            refresh()
        }
    }

    private func begin(from origin: Duration) {
        guard isEnabled(),
              let item,
              !item.subtitlesEnabled || item.isShowingSubtitlesOnSkipBack,
              let provider = item.mediaSession?.player as? MediaPlayerSubtitleCueProviding
        else {
            return
        }

        func isAvailable(_ index: Int) -> Bool {
            guard index >= 0,
                  let playerIndex = item.indexMap.playerIndex(for: index),
                  !item.isRebuildRequired(type: .subtitle, from: -1, to: index)
            else {
                return false
            }

            return provider.canObserveSubtitleCues(at: playerIndex)
        }

        let preferred = SubtitleTrackSelection(
            primary: item.configuration.disabledSubtitleTracks != nil || item.isShowingSubtitlesOnSkipBack
                ? item.subtitleTrackIndex(secondary: false) : -1,
            secondary: item.subtitleTrackIndex(secondary: true)
        )

        window = nil

        if item.isShowingSubtitlesOnSkipBack {
            item.setTemporarySubtitleTracks(nil)
        }

        preparation?.cancel()
        preparationOrigin = origin

        preparation = Task { [weak self, weak item] in
            guard let self, let item else {
                return
            }

            @MainActor
            func prepare(_ index: Int) async -> Bool {
                guard index >= 0, !item.isRebuildRequired(type: .subtitle, from: -1, to: index) else {
                    return false
                }

                if isAvailable(index) {
                    return true
                }

                _ = await item.prepareSubtitle(at: index)

                return !Task.isCancelled && isAvailable(index)
            }

            var tracks = preferred

            if await !prepare(tracks.primary) {
                tracks.primary = -1
            }

            if await !prepare(tracks.secondary) {
                tracks.secondary = -1
            }

            if tracks.primary < 0, tracks.secondary < 0 {
                var candidates = item.subtitleStreams.filter {
                    let index = $0.index ?? -1

                    return index >= 0 && !item.isRebuildRequired(type: .subtitle, from: -1, to: index)
                        && (isAvailable(index) || $0.isSidecarSubtitle)
                }

                while !Task.isCancelled,
                      let index = MediaPlaybackPreferences.current.subtitleForReplay(
                          in: candidates,
                          defaultIndex: item.mediaSource.defaultSubtitleStreamIndex
                      )
                {
                    if await prepare(index) {
                        tracks.primary = index
                        break
                    }

                    candidates.removeAll { $0.index == index }
                }
            }

            guard !Task.isCancelled else {
                return
            }

            preparation = nil
            preparationOrigin = nil

            guard self.item === item,
                  item.canSelectTracks,
                  !item.subtitlesEnabled || item.isShowingSubtitlesOnSkipBack,
                  tracks.primary >= 0 || tracks.secondary >= 0,
                  let position = item.mediaSession?.observedSeconds,
                  position < origin
            else {
                return
            }

            window = SkipBackSubtitles(from: origin, to: position)
            item.setTemporarySubtitleTracks(tracks)
            refresh()
        }
    }
}
