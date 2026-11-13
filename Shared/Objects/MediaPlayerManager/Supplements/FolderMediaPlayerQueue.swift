//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Observation

/// Plays the playable videos of one folder in order.
///
/// The folder is the direct parent of the video playback started with,
/// and only its direct children are queued (no recursion into
/// subfolders). The order is the folder's saved sort order, which
/// defaults to name ascending. When the last video ends, the queue
/// has no next item and playback stops.
@MainActor
@Observable
final class FolderMediaPlayerQueue: MediaPlayerQueue {

    private static let pageSize = 50

    private let parentID: String
    private let sortBy: [ItemSortBy]
    private let sortOrder: [ItemSortOrder]

    private(set) var state: MediaPlayerQueueState = .initial
    private(set) var items: [ItemEntry] = []

    private weak var mediaSession: MediaSession?
    private var userSession: UserSession?
    private var currentIndex: Int?
    private var isExhausted = false
    private var loadedCount = 0

    @ObservationIgnored
    private var loadTask: Task<Void, Error>?

    var currentEntryID: ItemEntry.ID? {
        currentIndex.map { items[$0].id }
    }

    var nextItem: PlaybackIntent? {
        guard let currentIndex, currentIndex + 1 < items.count else { return nil }

        return makeIntent(for: items[currentIndex + 1])
    }

    var previousItem: PlaybackIntent? {
        guard let currentIndex, currentIndex > 0 else { return nil }

        return makeIntent(for: items[currentIndex - 1])
    }

    init(
        parentID: String,
        sortBy: [ItemSortBy] = [ItemSortBy.sortName],
        sortOrder: [ItemSortOrder] = [ItemSortOrder.ascending]
    ) {
        self.parentID = parentID
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession
        self.userSession = mediaSession.userSession

        let observation = ObservationToken { [weak mediaSession] in
            mediaSession?.playbackItem?.baseItem.id
        } onChange: { [weak self] _ in
            self?.updateCurrentIndex()
        }

        startLoading()

        return AnyCancellable { [self, observation] in
            MainActor.assumeIsolated {
                observation.cancel()
                loadTask?.cancel()
                self.mediaSession = nil
            }
        }
    }

    func next() async throws -> PlaybackIntent? {
        try await loadTask?.value

        while nextItem == nil, !isExhausted {
            try await loadMore()
        }

        return nextItem
    }

    func refresh() {
        guard !isExhausted else { return }

        startLoading()
    }

    func select(_ entry: ItemEntry) {
        guard items.contains(entry) else { return }

        mediaSession?.playNewItem(intent: makeIntent(for: entry))
    }

    private func makeIntent(for entry: ItemEntry) -> PlaybackIntent {
        var configuration = MediaPlaybackConfiguration()
        configuration.startSeconds = .zero
        if let mediaSession {
            configuration.requestedBitrate = mediaSession.playbackBitrate
        }

        return PlaybackIntent(item: entry.snapshot, configuration: configuration, queue: self)
    }

    private func updateCurrentIndex() {
        guard let currentID = mediaSession?.playbackItem?.baseItem.id else { return }

        currentIndex = items.firstIndex { $0.itemID == currentID }
    }

    private func startLoading() {
        guard loadTask == nil else { return }

        loadTask = Task {
            defer { loadTask = nil }

            while !isExhausted {
                try await loadMore()
            }
        }
    }

    private func loadMore() async throws {
        guard let userSession else { throw UserSessionError.missingCurrentSession }

        state = items.isEmpty ? .loading : .content
        do {
            var parameters = Paths.GetItemsParameters()
            parameters.userID = userSession.user.id
            parameters.parentID = parentID
            parameters.isRecursive = false
            parameters.mediaTypes = [.video]
            parameters.includeItemTypes = [.episode, .movie, .video, .musicVideo, .trailer]
            parameters.isCollapseBoxSetItems = false
            parameters.isMissing = false
            parameters.isPlaceHolder = false
            parameters.enableUserData = true
            parameters.fields = PosterSubtitleField.itemFields
            parameters.sortBy = sortBy
            parameters.sortOrder = sortOrder
            parameters.limit = Self.pageSize
            parameters.startIndex = loadedCount

            let response = try await userSession.send(Paths.getItems(parameters: parameters))
            let page = response.items.map { ItemEntry(item: $0) }
            loadedCount += page.count
            isExhausted = page.count < Self.pageSize
            items.append(contentsOf: page.filter {
                $0.value.map { $0.mediaType == .video && $0.isPlayable && $0.isFolder != true } ?? false
            })
            state = .content
            updateCurrentIndex()
        } catch is CancellationError {
            state = .content
            throw CancellationError()
        } catch {
            state = .error
            throw error
        }
    }
}
