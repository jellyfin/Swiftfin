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

@Observable
final class EpisodeMediaPlayerQueue: MediaPlayerQueue {

    @ObservationIgnored
    private var currentAdjacentEpisodesTask: Task<Void, Error>? {
        didSet { oldValue?.cancel() }
    }

    @ObservationIgnored
    private var seasonLibrary: PagingLibraryViewModel<EpisodeLibrary>?
    @ObservationIgnored
    private var seasonObservation: AnyCancellable?

    private var itemsStorage = ValueBox<[ItemEntry]>(value: [])
    private weak var mediaSession: MediaSession?
    var nextItem: PlaybackIntent?
    var previousItem: PlaybackIntent?
    private(set) var state: MediaPlayerQueueState = .initial

    var currentEntryID: ItemEntry.ID? {
        mediaSession?.item.id.map { ItemEntry.ID(itemID: $0, occurrence: nil) }
    }

    var items: [ItemEntry] {
        itemsStorage.value
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession

        var previousItem = mediaSession.playbackItem
        didReceive(newItem: previousItem)

        let observation = Task { [weak self, weak mediaSession] in
            let items = ObservableValues { [weak mediaSession] in
                mediaSession?.playbackItem
            }

            for await item in items {
                guard !Task.isCancelled else { return }
                guard item === mediaSession?.playbackItem, item !== previousItem else { continue }

                previousItem = item
                self?.didReceive(newItem: item)
            }
        }

        return AnyCancellable { [self, observation] in
            MainActor.assumeIsolated {
                observation.cancel()
                didReceive(newItem: nil)
                resetSeason()
                self.mediaSession = nil
            }
        }
    }

    private func didReceive(newItem: MediaPlayerItem?) {
        currentAdjacentEpisodesTask = nil
        nextItem = nil
        previousItem = nil

        guard let newItem else { return }

        updateSeason(for: newItem.baseItem)

        currentAdjacentEpisodesTask = Task { [weak self] in
            try await self?.getAdjacentEpisodes(for: newItem.baseItem)
        }
    }

    func next() async throws -> PlaybackIntent? {
        try await currentAdjacentEpisodesTask?.value
        return nextItem
    }

    isolated deinit {
        currentAdjacentEpisodesTask?.cancel()
    }

    func refresh() {
        seasonLibrary?.refresh()
    }

    func select(_ entry: ItemEntry) {
        guard let mediaSession else { return }

        let configuration = with(MediaPlaybackConfiguration()) {
            $0.requestedBitrate = mediaSession.playbackBitrate
        }
        mediaSession.playNewItem(intent: PlaybackIntent(item: entry.snapshot, configuration: configuration))
    }

    private func updateSeason(for item: BaseItemDto) {
        guard item.type == .episode, let seasonID = item.seasonID?.nilIfBlank, let mediaSession else {
            resetSeason()
            return
        }
        guard seasonLibrary?.library.parent.id != seasonID else { return }

        resetSeason()

        let season = BaseItemDto(id: seasonID, name: item.seasonName, seriesID: item.seriesID, type: .season)
        let library = PagingLibraryViewModel(library: EpisodeLibrary(season: season), userSession: mediaSession.userSession)
        seasonLibrary = library

        seasonObservation = Task { [weak self] in
            let snapshots = ObservableValues {
                (elements: library.elements, state: library.state)
            }

            for await snapshot in snapshots {
                guard !Task.isCancelled, let self else { return }

                itemsStorage = .init(value: Array(snapshot.elements))
                state = switch snapshot.state {
                case .initial:
                    .initial
                case .refreshing:
                    .loading
                case .content:
                    .content
                case .error:
                    .error
                }
            }
        }
        .asAnyCancellable()

        refresh()
    }

    private func resetSeason() {
        seasonObservation = nil
        seasonLibrary?.core.cancelAll()
        seasonLibrary = nil
        itemsStorage = .init(value: [])
        state = .initial
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

        let configuration = with(MediaPlaybackConfiguration()) {
            $0.requestedBitrate = bitrate
            $0.startSeconds = .zero
        }
        let nextIntent = nextItem.map { PlaybackIntent(item: $0, configuration: configuration) }
        let previousIntent = previousItem.map { PlaybackIntent(item: $0, configuration: configuration) }

        guard !Task.isCancelled else { return }

        self.nextItem = nextIntent
        self.previousItem = previousIntent
    }
}
