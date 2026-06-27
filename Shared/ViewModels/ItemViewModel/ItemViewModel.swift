//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

// TODO: come up with a cleaner, more defined way for item update notifications

class ItemViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(ErrorMessage)
        case refresh
        case replace(BaseItemDto)
        case toggleIsFavorite
        case toggleIsPlayed
        case toggleIsInWatchlist
        case selectMediaSource(MediaSourceInfo)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    // TODO: create value on `BaseItemDto` whether an item
    //       only has children as playable items
    @Published
    private(set) var item: BaseItemDto {
        willSet {
            if item.isPlayable {
                playButtonItem = newValue
            }
        }
    }

    @Published
    var playButtonItem: BaseItemDto? {
        willSet {
            if let newValue {
                selectedMediaSource = newValue.mediaSources?.first
            }
        }
    }

    @Published
    private(set) var selectedMediaSource: MediaSourceInfo?
    @Published
    private(set) var similarItems: [BaseItemDto] = []
    @Published
    private(set) var specialFeatures: [BaseItemDto] = []
    @Published
    private(set) var localTrailers: [BaseItemDto] = []
    @Published
    private(set) var additionalParts: [BaseItemDto] = []

    @Published
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var state: State = .initial

    private var itemID: String {
        get throws {
            guard let id = item.id else {
                logger.error("Item ID is nil")
                throw ErrorMessage(L10n.unknownError)
            }
            return id
        }
    }

    // tasks

    private var toggleIsFavoriteTask: AnyCancellable?
    private var toggleIsPlayedTask: AnyCancellable?
    private var toggleWatchlistTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    // MARK: init

    @MainActor
    init(item: BaseItemDto) {
        self.item = item
        super.init()

        Notifications[.itemShouldRefreshMetadata]
            .publisher
            .sink { [weak self] itemID in
                guard itemID == self?.item.id else { return }

                Task {
                    await self?.send(.backgroundRefresh)
                }
            }
            .store(in: &cancellables)

        Notifications[.itemMetadataDidChange]
            .publisher
            .sink { [weak self] newItem in
                guard let newItemID = newItem.id, newItemID == self?.item.id else { return }

                Task {
                    await self?.send(.replace(newItem))
                }
            }
            .store(in: &cancellables)

        // Live user-data push (WebSocket → `UserDataSocketObserver`): when THIS item's played/favorite/
        // watchlist/progress changes on the server (e.g. from another client), patch its `userData` in
        // place from the fresh server data — instantly, without waiting on the heavier metadata refetch.
        Notifications[.itemUserDataDidChange]
            .publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] userData in
                guard let self, let itemID = userData.itemID, itemID == self.item.id else { return }
                guard self.item.userData != userData else { return }
                self.item.userData = userData
            }
            .store(in: &cancellables)
    }

    @MainActor
    convenience init(episode: BaseItemDto) {
        let shellSeriesItem = BaseItemDto(id: episode.seriesID, name: episode.seriesName)
        self.init(item: shellSeriesItem)
    }

    // MARK: respond

    func respond(to action: Action) -> State {
        switch action {
        case .backgroundRefresh:

            backgroundStates.insert(.refresh)

            Task { [weak self] in
                guard let self else { return }
                do {
                    // A background refresh (return-from-pushed-page / playback) ONLY re-fetches the full item,
                    // for live play / resume / watched state. The STATIC rows — More Like This, special
                    // features, local trailers — cannot change between leaving and returning to a detail page,
                    // so re-fetching them is pure waste AND caused a visible bug: the server's
                    // `/Items/{id}/Similar` returns a different top-N SUBSET on each call (ties in the
                    // similarity score get cut differently), so the `Set(ids)` membership genuinely changes →
                    // "More Like This" was reassigned and RESHUFFLED on every return, losing the last-focused
                    // card (the reported regression). Episode pages never showed it because they don't fetch
                    // similar items. Those rows are loaded once by `.refresh` (initial open / pull-to-refresh)
                    // and left untouched here. (Shared VM → applies to iOS too; correct there as well.)
                    let fullItem = try await getFullItem()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        if fullItem.id != self.item.id || fullItem != self.item {
                            self.item = fullItem
                        }
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .store(in: &cancellables)

            return state
        case let .error(error):
            return .error(error)
        case .refresh:

            refreshTask?.cancel()

            refreshTask = Task { [weak self] in
                guard let self else { return }
                do {
                    async let fullItem = getFullItem()
                    async let similarItems = getSimilarItems()
                    async let specialFeatures = getSpecialFeatures()
                    async let localTrailers = getLocalTrailers()
                    async let additionalParts = getAdditionalParts()

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures,
                        localTrailers: localTrailers,
                        additionalParts: additionalParts
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.item = results.fullItem
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures
                        self.localTrailers = results.localTrailers
                        self.additionalParts = results.additionalParts

                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        case let .replace(newItem):

            backgroundStates.insert(.refresh)

            Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        self.item = newItem
                    }
                }
            }
            .store(in: &cancellables)

            return state
        case .toggleIsFavorite:

            toggleIsFavoriteTask?.cancel()

            toggleIsFavoriteTask = Task {

                let beforeIsFavorite = item.userData?.isFavorite ?? false

                await MainActor.run {
                    item.userData?.isFavorite?.toggle()
                }

                do {
                    try await setIsFavorite(!beforeIsFavorite)
                } catch {
                    await MainActor.run {
                        item.userData?.isFavorite = beforeIsFavorite
                        // emit event that toggle unsuccessful
                    }
                }
            }
            .asAnyCancellable()

            return state
        case .toggleIsPlayed:

            toggleIsPlayedTask?.cancel()

            toggleIsPlayedTask = Task {

                let beforeIsPlayed = item.userData?.isPlayed ?? false

                await MainActor.run {
                    item.userData?.isPlayed?.toggle()
                }

                do {
                    try await setIsPlayed(!beforeIsPlayed)
                } catch {
                    await MainActor.run {
                        item.userData?.isPlayed = beforeIsPlayed
                        // emit event that toggle unsuccessful
                    }
                    return
                }

                // Marking an item watched removes it from the watchlist (the KefinTweaks
                // "Likes" flag), mirroring the server-side behavior.
                if !beforeIsPlayed, item.userData?.isLikes == true {
                    await MainActor.run {
                        item.userData?.isLikes = false
                    }
                    try? await setIsInWatchlist(false)
                }
            }
            .asAnyCancellable()

            return state
        case .toggleIsInWatchlist:

            toggleWatchlistTask?.cancel()

            toggleWatchlistTask = Task {

                let beforeIsInWatchlist = item.userData?.isLikes ?? false

                await MainActor.run {
                    item.userData?.isLikes = !beforeIsInWatchlist
                }

                do {
                    try await setIsInWatchlist(!beforeIsInWatchlist)
                } catch {
                    await MainActor.run {
                        item.userData?.isLikes = beforeIsInWatchlist
                    }
                }
            }
            .asAnyCancellable()

            return state
        case let .selectMediaSource(newSource):

            selectedMediaSource = newSource

            return state
        }
    }

    // Granular refresh switches so a subclass can skip network calls whose results its detail page
    // never displays. All default to `true` (fetch everything); subclasses override only what they
    // don't need. See `EpisodeItemViewModel` / `SeriesItemViewModel` (episode page) for the rationale.

    /// Re-fetch the full item on refresh. A view model that was already handed a complete item (e.g.
    /// the series hosted inside an episode page) can set this to `false` to avoid a redundant fetch.
    var fetchesFullItem: Bool {
        true
    }

    /// Fetch "More Like This" similar items.
    var fetchesSimilarItems: Bool {
        true
    }

    /// Fetch the item's extras — special features, local trailers and additional parts.
    var fetchesExtras: Bool {
        true
    }

    private func getFullItem() async throws -> BaseItemDto {
        // Already have a complete item — return it unchanged rather than re-downloading it.
        guard fetchesFullItem else { return item }
        return try await item.getFullItem(userSession: requireUserSession(), sendNotification: true)
    }

    private func getSimilarItems() async throws -> [BaseItemDto] {
        guard fetchesSimilarItems else { return [] }
        guard let itemID = item.id else { return [] }

        var parameters = Paths.GetSimilarItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 20

        let request = Paths.getSimilarItems(
            itemID: itemID,
            parameters: parameters
        )

        let response = try? await send(request)

        return response?.value.items ?? []
    }

    private func getSpecialFeatures() async throws -> [BaseItemDto] {
        guard fetchesExtras else { return [] }
        guard let itemID = item.id else { return [] }

        let request = try Paths.getSpecialFeatures(
            itemID: itemID,
            userID: authenticatedUser.id
        )
        let response = try? await send(request)

        return (response?.value ?? [])
            .filter { $0.extraType?.isVideo ?? false }
    }

    private func getLocalTrailers() async throws -> [BaseItemDto] {
        guard fetchesExtras else { return [] }

        let request = try Paths.getLocalTrailers(itemID: itemID, userID: authenticatedUser.id)
        let response = try? await send(request)

        return response?.value ?? []
    }

    private func getAdditionalParts() async throws -> [BaseItemDto] {
        guard fetchesExtras else { return [] }

        guard let partCount = item.partCount,
              partCount > 1,
              let itemID = item.id else { return [] }

        let request = Paths.getAdditionalPart(itemID: itemID)
        let response = try? await send(request)

        return response?.value.items ?? []
    }

    // `itemID` defaults to this view model's own item, but callers (e.g. an episode acting on its
    // parent series) may target a different item.
    func setIsPlayed(_ isPlayed: Bool, itemID: String? = nil) async throws {

        guard let itemID = itemID ?? item.id else { return }

        let request: Request<UserItemDataDto> = if isPlayed {
            try Paths.markPlayedItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        } else {
            try Paths.markUnplayedItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        }

        _ = try await send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    func setIsFavorite(_ isFavorite: Bool, itemID: String? = nil) async throws {

        guard let itemID = itemID ?? item.id else { return }

        let request: Request<UserItemDataDto> = if isFavorite {
            try Paths.markFavoriteItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        } else {
            try Paths.unmarkFavoriteItem(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        }

        _ = try await send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    /// Adds/removes the item from the watchlist. Matches the KefinTweaks plugin, whose
    /// watchlist is the Jellyfin "Likes" user-data flag (`/UserItems/{id}/Rating`).
    func setIsInWatchlist(_ isInWatchlist: Bool, itemID: String? = nil) async throws {

        guard let itemID = itemID ?? item.id else { return }

        let request: Request<UserItemDataDto> = if isInWatchlist {
            try Paths.updateUserItemRating(
                itemID: itemID,
                userID: authenticatedUser.id,
                isLikes: true
            )
        } else {
            try Paths.deleteUserItemRating(
                itemID: itemID,
                userID: authenticatedUser.id
            )
        }

        _ = try await send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }
}
