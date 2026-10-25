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

@MainActor
@Observable
final class ShuffleMediaPlayerQueue: MediaPlayerQueue {

    typealias PageLoader = @MainActor (Paths.GetItemsParameters, UserSession) async throws -> [ItemEntry]

    private static let pageSize = 20
    private static let refillThreshold = 10

    private struct CollectionSource {
        var items: [ItemEntry] = []
        var excludedIDs: Set<String> = []
        var isExhausted = false
    }

    private(set) var state: MediaPlayerQueueState = .initial
    private(set) var items: [ItemEntry] = []

    private let parent: ItemEntry
    private var userSession: UserSession?
    private let loadPage: PageLoader
    private weak var mediaSession: MediaSession?
    private var currentIndex: Int?
    private var excludedIDs: Set<String> = []
    private var isExhausted = false
    private var collections: CollectionSource?

    @ObservationIgnored
    private var refillTask: Task<Void, Error>?

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
        parent: BaseItemDto,
        loadPage: @escaping PageLoader = { parameters, userSession in
            let response = try await userSession.send(Paths.getItems(parameters: parameters))
            return response.items.map { ItemEntry(item: $0) }
        }
    ) {
        self.parent = SharedBaseItem(wrappedValue: parent).entry
        self.loadPage = loadPage
        if parent.collectionType == .boxsets {
            collections = CollectionSource()
        }
    }

    func resolve(_ intent: PlaybackIntent, userSession: UserSession) async throws -> PlaybackIntent {
        self.userSession = userSession
        guard intent.entry.itemID == parent.itemID else { return intent }

        if items.isEmpty, isExhausted {
            excludedIDs.removeAll()
            isExhausted = false
            if collections != nil {
                collections = CollectionSource()
            }
        }

        if items.isEmpty {
            try await loadMore()
        }

        guard let first = items.first else { throw ErrorMessage(L10n.noItems) }

        var configuration = intent.configuration
        configuration.startSeconds = .zero
        return PlaybackIntent(item: first.snapshot, configuration: configuration, queue: self)
    }

    func next() async throws -> PlaybackIntent? {
        guard currentIndex != nil else { return nil }

        try await refillTask?.value
        if nextItem == nil, !isExhausted {
            try await loadMore()
        }

        return nextItem
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        self.mediaSession = mediaSession

        let observation = ObservationToken { [weak mediaSession] in
            mediaSession?.playbackItem?.baseItem.id
        } onChange: { [weak self] itemID in
            guard let self, let itemID else { return }

            currentIndex = items.firstIndex { $0.itemID == itemID }
            if let currentIndex, items.count - currentIndex - 1 <= Self.refillThreshold, state != .error {
                refresh()
            }
        }

        return AnyCancellable { [self, observation] in
            MainActor.assumeIsolated {
                observation.cancel()
                refillTask?.cancel()
                self.mediaSession = nil
            }
        }
    }

    func refresh() {
        guard currentIndex != nil, !isExhausted, refillTask == nil else { return }

        refillTask = Task {
            defer { refillTask = nil }
            try await loadMore()
        }
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

    private func loadMore() async throws {
        guard let userSession else { throw UserSessionError.missingCurrentSession }

        state = items.isEmpty ? .loading : .content
        let previousCount = items.count
        do {
            repeat {
                var parameters = Paths.GetItemsParameters()
                parameters.userID = userSession.user.id
                parameters.parentID = parent.itemID
                parameters.isRecursive = true
                parameters.mediaTypes = [.video]
                parameters.includeItemTypes = [.episode, .movie, .video, .musicVideo, .trailer]
                parameters.isCollapseBoxSetItems = false
                parameters.isMissing = false
                parameters.isPlaceHolder = false
                parameters.enableUserData = true
                parameters.fields = PosterSubtitleField.itemFields
                parameters.sortBy = [.random]
                parameters.limit = Self.pageSize
                // Random results have no stable offset. Exclude fetched IDs instead.
                parameters.excludeItemIDs = Array(excludedIDs)

                let page = try await fetchPage(parameters, userSession: userSession)
                let newItems = page.filter { excludedIDs.insert($0.itemID).inserted }
                isExhausted = isExhausted || newItems.isEmpty
                items.append(contentsOf: newItems.filter {
                    $0.value.map { $0.mediaType == .video && $0.isPlayable && $0.isFolder != true } ?? false
                })
            } while items.count == previousCount && !isExhausted
            state = .content
        } catch is CancellationError {
            state = .content
            throw CancellationError()
        } catch {
            state = .error
            throw error
        }
    }

    private func fetchPage(_ parameters: Paths.GetItemsParameters, userSession: UserSession) async throws -> [ItemEntry] {
        guard var collections else {
            let page = try await loadPage(parameters, userSession)
            isExhausted = page.count < Self.pageSize
            return page
        }

        // The virtual Collections library links to collections, not physical videos.
        // Page through those collections and query their playable children in turn.
        while true {
            if collections.items.isEmpty, !collections.isExhausted {
                var query = parameters
                query.isRecursive = false
                query.mediaTypes = nil
                query.includeItemTypes = [.boxSet]
                query.excludeItemIDs = Array(collections.excludedIDs)
                let page = try await loadPage(query, userSession)
                let newItems = page.filter { collections.excludedIDs.insert($0.itemID).inserted }
                collections.isExhausted = page.count < Self.pageSize || newItems.isEmpty
                collections.items = newItems.filter { $0.snapshot.type == .boxSet }
            }

            guard let collection = collections.items.first else {
                self.collections = collections
                isExhausted = collections.isExhausted
                if isExhausted {
                    return []
                }
                continue
            }

            var query = parameters
            query.parentID = collection.itemID
            let page = try await loadPage(query, userSession)
            let newItems = page.filter { !excludedIDs.contains($0.itemID) }
            collections.items.removeFirst()
            if page.count == Self.pageSize, !newItems.isEmpty {
                collections.items.append(collection)
            }
            if !newItems.isEmpty {
                self.collections = collections
                isExhausted = collections.isExhausted && collections.items.isEmpty
                return newItems
            }
        }
    }
}
