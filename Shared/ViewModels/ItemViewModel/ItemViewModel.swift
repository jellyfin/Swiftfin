//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        case error(JellyfinAPIError)
        case refresh
        case replace(BaseItemDto)
        case toggleIsFavorite
        case toggleIsPlayed
        case selectMediaSource(MediaSourceInfo)
    }

    // MARK: BackgroundState

    enum BackgroundState: Hashable {
        case refresh
        case shuffling
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
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
                throw JellyfinAPIError(L10n.unknownError)
            }
            return id
        }
    }

    // tasks

    private var toggleIsFavoriteTask: AnyCancellable?
    private var toggleIsPlayedTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    // MARK: init

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
    }

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
                    async let fullItem = getFullItem()
                    async let similarItems = getSimilarItems()
                    async let specialFeatures = getSpecialFeatures()
                    async let localTrailers = getLocalTrailers()

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures,
                        localTrailers: localTrailers
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        if results.fullItem.id != self.item.id || results.fullItem != self.item {
                            self.item = results.fullItem
                        }

                        if !results.similarItems.elementsEqual(self.similarItems, by: { $0.id == $1.id }) {
                            self.similarItems = results.similarItems
                        }

                        if !results.specialFeatures.elementsEqual(self.specialFeatures, by: { $0.id == $1.id }) {
                            self.specialFeatures = results.specialFeatures
                        }

                        if !results.localTrailers.elementsEqual(self.localTrailers, by: { $0.id == $1.id }) {
                            self.localTrailers = results.localTrailers
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
                }
            }
            .asAnyCancellable()

            return state
        case let .selectMediaSource(newSource):

            selectedMediaSource = newSource

            return state
        }
    }

    private func getFullItem() async throws -> BaseItemDto {
        try await item.getFullItem(userSession: userSession)
    }

    private func getSimilarItems() async -> [BaseItemDto] {

        var parameters = Paths.GetSimilarItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 20
        parameters.userID = userSession.user.id

        let request = Paths.getSimilarItems(
            itemID: item.id!,
            parameters: parameters
        )

        let response = try? await userSession.client.send(request)

        return response?.value.items ?? []
    }

    private func getSpecialFeatures() async -> [BaseItemDto] {

        let request = Paths.getSpecialFeatures(
            itemID: item.id!,
            userID: userSession.user.id
        )
        let response = try? await userSession.client.send(request)

        return (response?.value ?? [])
            .filter { $0.extraType?.isVideo ?? false }
    }

    private func getLocalTrailers() async throws -> [BaseItemDto] {

        let request = try Paths.getLocalTrailers(itemID: itemID, userID: userSession.user.id)
        let response = try? await userSession.client.send(request)

        return response?.value ?? []
    }

    private func getAdditionalParts() async throws -> [BaseItemDto] {

        guard let partCount = item.partCount,
              partCount > 1,
              let itemID = item.id else { return [] }

        let request = Paths.getAdditionalPart(itemID: itemID)
        let response = try? await userSession.client.send(request)

        return response?.value.items ?? []
    }

    // MARK: - Get Shuffled Items

    @MainActor
    func getShuffledItems(excluding excludeItemIDs: [String] = []) async throws -> [BaseItemDto] {
        []
    }

    @MainActor
    static func fetchShuffledItemsPaginated(
        userSession: UserSession,
        parentID: String?,
        includeItemTypes: [BaseItemKind],
        excludeItemIDs: [String] = [],
        enableUserData: Bool = false,
        isMissing: Bool? = nil,
        filterPlayable: Bool = false,
        applyParentParameters: ((Paths.GetItemsByUserIDParameters) -> Paths.GetItemsByUserIDParameters)? = nil
    ) async throws -> [BaseItemDto] {
        let pageSize = ShuffleQueueConstants.pageSize
        let maxItems = ShuffleQueueConstants.targetQueueSize
        var allItems: [BaseItemDto] = []
        var startIndex = 0
        var currentExcludeIDs = excludeItemIDs

        while allItems.count < maxItems {
            var parameters = Paths.GetItemsByUserIDParameters()
            parameters.enableUserData = enableUserData
            parameters.fields = .MinimumFields
            parameters.isRecursive = true
            parameters.parentID = parentID
            parameters.sortBy = [ItemSortBy.random.rawValue]
            parameters.includeItemTypes = includeItemTypes
            parameters.limit = min(pageSize, maxItems - allItems.count)
            parameters.startIndex = startIndex

            if let isMissing = isMissing {
                parameters.isMissing = isMissing
            }

            if currentExcludeIDs.isNotEmpty {
                parameters.excludeItemIDs = currentExcludeIDs
            }

            if let applyParentParameters = applyParentParameters {
                parameters = applyParentParameters(parameters)
            }

            let request = Paths.getItemsByUserID(
                userID: userSession.user.id,
                parameters: parameters
            )
            let response = try await userSession.client.send(request)

            var pageItems = response.value.items ?? []
            if filterPlayable {
                pageItems = pageItems.filter(\.isPlayable)
            }
            allItems.append(contentsOf: pageItems)

            currentExcludeIDs.append(contentsOf: pageItems.compactMap(\.id))

            if pageItems.count < pageSize || allItems.count >= maxItems {
                break
            }

            startIndex += pageSize
        }

        return allItems
    }

    // MARK: - Play Shuffle

    func playShuffle(router: NavigationCoordinator.Router) {
        guard item.canShuffle else {
            logger.error("Shuffle not supported for item type: \(String(describing: item.type))")
            return
        }

        backgroundStates.insert(.shuffling)

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let shuffledItems = try await self.getShuffledItems()

                guard shuffledItems.isNotEmpty else {
                    self.logger.error("No items to shuffle")
                    self.backgroundStates.remove(.shuffling)
                    return
                }

                guard var firstItem = shuffledItems.first else {
                    self.logger.error("No first item in shuffled list")
                    self.backgroundStates.remove(.shuffling)
                    return
                }

                firstItem.userData?.playbackPositionTicks = 0

                let fetchState = ShuffleActionHelper.FetchState(excludeItemIDs: Set(shuffledItems.compactMap(\.id)))
                let fetchMoreItems: () async throws -> [BaseItemDto] = { [weak self, fetchState] in
                    guard let self else { return [] }
                    let newItems = try await self.getShuffledItems(excluding: Array(fetchState.excludeItemIDs))
                    fetchState.excludeItemIDs.formUnion(newItems.compactMap(\.id))
                    return newItems
                }

                let queue = ShuffleMediaPlayerQueue(items: shuffledItems, fetchMoreItems: fetchMoreItems)

                let mediaSource: MediaSourceInfo?
                #if os(tvOS)
                let containerTypes: Set<BaseItemKind> = [.series, .boxSet, .collectionFolder, .folder, .playlist]
                if let itemType = self.item.type, containerTypes.contains(itemType) {
                    mediaSource = MediaSourceInfo()
                } else {
                    guard let selectedMediaSource = self.selectedMediaSource else {
                        self.logger.error("Shuffle selected with no media source for playable item")
                        self.backgroundStates.remove(.shuffling)
                        return
                    }
                    mediaSource = selectedMediaSource
                }
                #else
                mediaSource = nil
                #endif

                let manager = self.createShuffleManager(
                    firstItem: firstItem,
                    queue: queue,
                    mediaSource: mediaSource
                )

                self.setupShuffleLoaderObservers(manager: manager)
                router.route(to: .videoPlayer(manager: manager))
            } catch {
                self.logger.error("Error shuffling items: \(error)")
                self.backgroundStates.remove(.shuffling)
            }
        }
    }

    @MainActor
    private func createShuffleManager(
        firstItem: BaseItemDto,
        queue: ShuffleMediaPlayerQueue,
        mediaSource: MediaSourceInfo?
    ) -> MediaPlayerManager {
        MediaPlayerManager(
            item: firstItem,
            queue: queue
        ) { item in
            if let mediaSource {
                try await MediaPlayerItem.build(for: item, mediaSource: mediaSource)
            } else {
                try await MediaPlayerItem.build(for: item) {
                    $0.userData?.playbackPositionTicks = 0
                }
            }
        }
    }

    @MainActor
    private func setupShuffleLoaderObservers(manager: MediaPlayerManager) {
        manager.$state
            .sink { [weak self] state in
                if state == .playback {
                    self?.backgroundStates.remove(.shuffling)
                }
            }
            .store(in: &manager.cancellables)

        manager.$playbackItem
            .sink { [weak self] playbackItem in
                if playbackItem != nil {
                    self?.backgroundStates.remove(.shuffling)
                }
            }
            .store(in: &manager.cancellables)
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {

        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        } else {
            request = Paths.markUnplayedItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {

        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto>

        if isFavorite {
            request = Paths.markFavoriteItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        } else {
            request = Paths.unmarkFavoriteItem(
                itemID: item.id!,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)
        Notifications[.itemShouldRefreshMetadata].post(itemID)
    }
}
