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
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    private(set) var item: BaseItemDto {
        willSet {
            switch item.type {
            case .episode, .movie:
                guard !item.isMissing else { return }
                playButtonItem = newValue
            default: ()
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
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var state: State = .initial

    // tasks

    private var toggleIsFavoriteTask: AnyCancellable?
    private var toggleIsPlayedTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    // MARK: init

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        Notifications[.didItemUserDataChange]
            .publisher
            .sink { [weak self] itemID in
                guard let self = self, (itemID == item.id || itemID == playButtonItem?.id) else { return }

                Task {
                    await self.send(.backgroundRefresh)
                }
            }
            .store(in: &cancellables)

        Notifications[.didItemMetadataChange]
            .publisher
            .sink { [weak self] newItem in
                guard let self = self,
                      (newItem.id == item.id && newItem != item) ||
                      (newItem.id == playButtonItem?.id && newItem != playButtonItem)
                else { return }

                /// Replace if the item was updated
                /// Refresh if the playButtonItem was updated
                Task {
                    if newItem.id == item.id {
                        await MainActor.run {
                            self.item = newItem
                        }
                    } else {
                        await self.send(.backgroundRefresh)
                    }
                }
            }
            .store(in: &cancellables)
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

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures,
                        localTrailers: localTrailers
                    )

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.item = results.fullItem
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures
                        self.localTrailers = results.localTrailers

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
                let beforePlaybackPosition = item.userData?.playbackPositionTicks

                await MainActor.run {
                    item.userData?.isPlayed?.toggle()
                    item.userData?.playbackPositionTicks = nil
                }

                do {
                    try await setIsPlayed(!beforeIsPlayed)
                } catch {
                    await MainActor.run {
                        item.userData?.isPlayed = beforeIsPlayed
                        item.userData?.playbackPositionTicks = beforePlaybackPosition
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

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.ids = [item.id!]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let fullItem = response.value.items?.first else { throw JellyfinAPIError("Full item not in response") }

        return fullItem
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

        guard let itemID = item.id else { return [] }

        let request = Paths.getLocalTrailers(itemID: itemID, userID: userSession.user.id)
        let response = try? await userSession.client.send(request)

        return response?.value ?? []
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {

        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            request = Paths.markUnplayedItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didItemMetadataChange].post(item)
        }
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {

        guard let itemID = item.id else { return }

        let request: Request<UserItemDataDto>

        if isFavorite {
            request = Paths.markFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        } else {
            request = Paths.unmarkFavoriteItem(
                itemID: itemID,
                userID: userSession.user.id
            )
        }

        _ = try await userSession.client.send(request)

        await MainActor.run {
            Notifications[.didItemMetadataChange].post(item)
        }
    }
}
