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
