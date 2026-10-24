//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import Observation

@MainActor
@Observable
final class EpisodeMediaPlayerQueue: MediaPlayerQueue {

    private weak var mediaSession: MediaSession?
    var nextItem: PlaybackIntent?
    var previousItem: PlaybackIntent?

    @ObservationIgnored
    private var currentAdjacentEpisodesTask: AnyCancellable?

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession

        let observation = MediaPlayerObservation { [weak mediaSession] in
            mediaSession?.playbackItem
        } onChange: { [weak self] item in
            self?.didReceive(newItem: item)
        }

        return AnyCancellable { [self, observation] in
            MainActor.assumeIsolated {
                observation.cancel()
                didReceive(newItem: nil)
                self.mediaSession = nil
            }
        }
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        currentAdjacentEpisodesTask = nil
        nextItem = nil
        previousItem = nil

        guard let newItem else { return }

        currentAdjacentEpisodesTask = Task { [weak self] in
            try await self?.getAdjacentEpisodes(for: newItem.baseItem)
        }
        .asAnyCancellable()
    }

    private func getAdjacentEpisodes(for item: BaseItemDto?) async throws {
        guard let item, let seriesID = item.seriesID, item.type == .episode else { return }
        guard let session = mediaSession?.userSession else {
            throw UserSessionError.missingCurrentSession
        }

        let parameters = Paths.GetEpisodesParameters(
            userID: session.user.id,
            adjacentTo: item.id!,
            limit: 3
        )

        let request = Paths.getEpisodes(seriesID: seriesID, parameters: parameters)
        let response = try await session.send(request)

        // 4 possible states:
        //  1 - only current episode
        //  2 - two episodes with next episode
        //  3 - two episodes with previous episode
        //  4 - three episodes with current in middle

        // 1
        guard let items = response.value.items, items.count > 1 else { return }

        var previousItem: BaseItemDto?
        var nextItem: BaseItemDto?

        if items.count == 2 {
            if items[0].id == item.id {
                // 2
                nextItem = items[1]

            } else {
                // 3
                previousItem = items[0]
            }
        } else {
            nextItem = items[2]
            previousItem = items[0]
        }

        let bitrate = mediaSession?.playbackBitrate ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate]

        let nextIntent = nextItem.map {
            PlaybackIntent(item: $0, requestedBitrate: bitrate).updating(startSeconds: .zero)
        }

        let previousIntent = previousItem.map {
            PlaybackIntent(item: $0, requestedBitrate: bitrate).updating(startSeconds: .zero)
        }

        guard !Task.isCancelled else { return }

        self.nextItem = nextIntent
        self.previousItem = previousIntent
    }
}
