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
import UIKit

// TODO: transition to `Stateful`
class ItemViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action {
        case error(JellyfinAPIError)
        case refresh
        case toggleFavorite
        case toggleWatched
    }

    // MARK: State

    enum State: Equatable {
        case error(JellyfinAPIError)
        case item
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
    private(set) var playButtonItem: BaseItemDto? {
        willSet {
            if let newValue {
                selectedMediaSource = newValue.mediaSources?.first
            }
        }
    }

//    @Published
//    var isFavorited = false
//    @Published
//    var isPlayed = false
    @Published
    private(set) var selectedMediaSource: MediaSourceInfo?
    @Published
    private(set) var similarItems: [BaseItemDto] = []
    @Published
    private(set) var specialFeatures: [BaseItemDto] = []

    @Published
    var state: State = .item

    private var refreshTask: AnyCancellable?

    init(item: BaseItemDto) {
        self.item = item
        super.init()

//        getFullItem()

//        isFavorited = item.userData?.isFavorite ?? false
//        isPlayed = item.userData?.isPlayed ?? false

//        Notifications[.didEndPlayback].publiser
//            .sink { [weak self] notification in
//                guard let userInfo = notification.userInfo else { return }
//
//                if let playbackItem = userInfo["playbackItem"] as? BaseItemDto {
//
//                }
//            }
//            .store(in: &cancellables)
    }

    func respond(to action: Action) -> State {
        switch action {
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

                    await MainActor.run {
                        self.item = results.fullItem
                        self.similarItems = results.similarItems
                        self.specialFeatures = results.specialFeatures

                        self.state = .item
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    // TODO: error
                }
            }
            .asAnyCancellable()

            return .refreshing
        case .toggleFavorite:
            return state
        case .toggleWatched:
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
            userID: userSession.user.id,
            itemID: item.id!
        )
        let response = try? await userSession.client.send(request)

        return (response?.value ?? [])
            .filter { $0.extraType?.isVideo ?? false }
    }

    private func toggleWatchState() async throws {

        guard let isPlayed = item.userData?.isPlayed else { throw JellyfinAPIError("Item doesn't have expected user data") }

        let request: Request<UserItemDataDto>

        if isPlayed {
            request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        } else {
            request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        }

        let response = try await userSession.client.send(request)

//        let current = isPlayed
//        isPlayed.toggle()
//        let request: AnyPublisher<UserItemDataDto, Error>

//        if current {
//            request = PlaystateAPI.markUnplayedItem(userId: "123abc", itemId: item.id!)
//        } else {
//            request = PlaystateAPI.markPlayedItem(userId: "123abc", itemId: item.id!)
//        }

//        request
//            .trackActivity(loading)
//            .sink(receiveCompletion: { [weak self] completion in
//                switch completion {
//                case .failure:
//                    self?.isPlayed = !current
//                case .finished: ()
//                }
//                self?.handleAPIRequestError(completion: completion)
//            }, receiveValue: { _ in })
//            .store(in: &cancellables)
    }

    private func toggleFavoriteState() async throws {

        guard let isFavorite = item.userData?.isFavorite else { throw JellyfinAPIError("Item doesn't have expected user data") }

        let request: Request<UserItemDataDto>

        if isFavorite {
            request = Paths.unmarkFavoriteItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        } else {
            request = Paths.markFavoriteItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
        }

        let response = try await userSession.client.send(request)

//        let current = isFavorited
//        isFavorited.toggle()
//        let request: AnyPublisher<UserItemDataDto, Error>

//        if current {
//            request = UserLibraryAPI.unmarkFavoriteItem(userId: "123abc", itemId: item.id!)
//        } else {
//            request = UserLibraryAPI.markFavoriteItem(userId: "123abc", itemId: item.id!)
//        }

//        request
//            .trackActivity(loading)
//            .sink(receiveCompletion: { [weak self] completion in
//                switch completion {
//                case .failure:
//                    self?.isFavorited = !current
//                case .finished: ()
//                }
//                self?.handleAPIRequestError(completion: completion)
//            }, receiveValue: { _ in })
//            .store(in: &cancellables)
    }
}
