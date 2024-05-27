//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import Get
import JellyfinAPI
import OrderedCollections
import UIKit

class ItemViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(JellyfinAPIError)
        case refresh
        case toggleIsFavorite
        case toggleIsPlayed
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
    public var item: BaseItemDto {
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
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var lastAction: Action? = nil
    @Published
    final var state: State = .initial

    // tasks

    private var toggleIsFavoriteTask: AnyCancellable?
    private var toggleIsPlayedTask: AnyCancellable?
    private var refreshTask: AnyCancellable?

    // MARK: init

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        // TODO: should replace with a more robust "PlaybackManager"
        Notifications[.itemMetadataDidChange].publisher
            .sink { [weak self] notification in

                guard let userInfo = notification.object as? [String: String] else { return }

                if let itemID = userInfo["itemID"], itemID == item.id {
                    Task { [weak self] in
                        await self?.send(.backgroundRefresh)
                    }
                } else if let seriesID = userInfo["seriesID"], seriesID == item.id {
                    Task { [weak self] in
                        await self?.send(.backgroundRefresh)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: respond

    public func respond(to action: Action) -> State {
        switch action {
        case .backgroundRefresh:

            backgroundStates.append(.refresh)

            Task { [weak self] in
                guard let self else { return }
                do {
                    async let fullItem = getFullItem()
                    async let similarItems = getSimilarItems()
                    async let specialFeatures = getSpecialFeatures()

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures
                    )

                    guard !Task.isCancelled else { return }

                    try await onRefresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.backgroundStates.remove(.refresh)
                        self.item = results.fullItem
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures
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

                    let results = try await (
                        fullItem: fullItem,
                        similarItems: similarItems,
                        specialFeatures: specialFeatures
                    )

                    guard !Task.isCancelled else { return }

                    try await onRefresh()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.item = results.fullItem
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures

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
        }
    }

    func onRefresh() async throws {}

    func getFullItem() async throws -> BaseItemDto {

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
            userID: userSession.user.id,
            itemID: item.id!
        )
        let response = try? await userSession.client.send(request)

        return (response?.value ?? [])
            .filter { $0.extraType?.isVideo ?? false }
    }

    private func setIsPlayed(_ isPlayed: Bool) async throws {

        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        } else {
            request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        }

        let _ = try await userSession.client.send(request)

        let ids = ["itemID": item.id]
        Notifications[.itemMetadataDidChange].post(object: ids)
    }

    private func setIsFavorite(_ isFavorite: Bool) async throws {

        let request: Request<UserItemDataDto>

        if isFavorite {
            request = Paths.markFavoriteItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        } else {
            request = Paths.unmarkFavoriteItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        }

        let _ = try await userSession.client.send(request)
    }
}
