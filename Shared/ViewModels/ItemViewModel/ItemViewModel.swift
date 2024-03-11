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
import JellyfinAPI
import UIKit

// TODO: transition to `Stateful`
class ItemViewModel: ViewModel {

    @Published
    var item: BaseItemDto {
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
    var isFavorited = false
    @Published
    var isPlayed = false
    @Published
    var selectedMediaSource: MediaSourceInfo?
    @Published
    var similarItems: [BaseItemDto] = []
    @Published
    var specialFeatures: [BaseItemDto] = []

    init(item: BaseItemDto) {
        self.item = item
        super.init()

        getFullItem()

        isFavorited = item.userData?.isFavorite ?? false
        isPlayed = item.userData?.isPlayed ?? false

        getSimilarItems()
        getSpecialFeatures()

        Notifications[.didSendStopReport].subscribe(self, selector: #selector(receivedStopReport(_:)))
    }

    private func getFullItem() {
        Task {

            await MainActor.run {
                isLoading = true
            }

            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                fields: ItemFields.allCases,
                enableUserData: true,
                ids: [item.id!]
            )

            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let fullItem = response.value.items?.first else { return }

            await MainActor.run {
                self.item = fullItem
                isLoading = false
            }
        }
    }

    @objc
    private func receivedStopReport(_ notification: NSNotification) {
        guard let itemID = notification.object as? String else { return }

        if itemID == item.id {
            updateItem()
        } else {
            // Remove if necessary. Note that this cannot be in deinit as
            // holding as an observer won't allow the object to be deinit-ed
            Notifications[.didSendStopReport].unsubscribe(self)
        }
    }

    // TODO: remove and have views handle
    func playButtonText() -> String {

        if item.isUnaired {
            return L10n.unaired
        }

        if item.isMissing {
            return L10n.missing
        }

        if let itemProgressString = item.progressLabel {
            return itemProgressString
        }

        return L10n.play
    }

    func getSimilarItems() {
        Task {
            let parameters = Paths.GetSimilarItemsParameters(
                userID: userSession.user.id,
                limit: 20,
                fields: .MinimumFields
            )
            let request = Paths.getSimilarItems(
                itemID: item.id!,
                parameters: parameters
            )
            let response = try await userSession.client.send(request)

            await MainActor.run {
                similarItems = response.value.items ?? []
            }
        }
    }

    func getSpecialFeatures() {
        Task {
            let request = Paths.getSpecialFeatures(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let response = try await userSession.client.send(request)

            await MainActor.run {
                specialFeatures = response.value.filter { $0.extraType?.isVideo ?? false }
            }
        }
    }

    func toggleWatchState() {
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

    func toggleFavoriteState() {
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

    // Overridden by subclasses
    func updateItem() {}
}
