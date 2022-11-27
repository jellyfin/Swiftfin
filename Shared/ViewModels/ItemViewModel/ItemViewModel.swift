//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import UIKit

class ItemViewModel: ViewModel {

    @Published
    var item: BaseItemDto {
        willSet {
            switch item.type {
            case .episode, .movie:
                if !item.missing && !item.unaired {
                    playButtonItem = newValue
                }
            default: ()
            }
        }
    }
    @Published
    var playButtonItem: BaseItemDto? {
        willSet {
            if let newValue {
                refreshItemVideoPlayerViewModel(for: newValue)
            }
        }
    }

    @Published
    var similarItems: [BaseItemDto] = []
    @Published
    var specialFeatures: [BaseItemDto] = []
    @Published
    var isPlayed = false
    @Published
    var isFavorited = false
    
    @Published
    var selectedMediaSource: MediaSourceInfo?

//    @Published
//    var selectedVideoPlayerViewModel: VideoPlayerViewModel?
//    @Published
//    var videoPlayerViewModels: [VideoPlayerViewModel] = []

    init(item: BaseItemDto) {
        self.item = item
        super.init()
        
        getFullItem()

        switch item.type {
        case .episode, .movie:
            if !item.missing && !item.unaired {
                self.playButtonItem = item
            }
        default: ()
        }

        isFavorited = item.userData?.isFavorite ?? false
        isPlayed = item.userData?.played ?? false

        getSimilarItems()
        getSpecialFeatures()
        refreshItemVideoPlayerViewModel(for: item)

        Notifications[.didSendStopReport].subscribe(self, selector: #selector(receivedStopReport(_:)))
    }
    
    private func getFullItem() {
        guard let itemID = item.id else { logger.error("Unable to retrieve full item: no item ID"); return }
        
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            fields: ItemFields.allCases,
            enableUserData: true,
            ids: [itemID]
        )
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            guard let self, let fullItem = response.items?.first else { self?.logger.error("Unable to retrieve full item: item not in response"); return }
            self.item = fullItem
        }
        .store(in: &cancellables)
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

    func refreshItemVideoPlayerViewModel(for item: BaseItemDto) {
        guard item.type == .episode || item.type == .movie,
              !item.missing else { return }

//        item.createItemVideoPlayerViewModel()
//            .sink { completion in
//                self.handleAPIRequestError(completion: completion)
//            } receiveValue: { viewModels in
//                self.videoPlayerViewModels = viewModels
//                self.selectedVideoPlayerViewModel = viewModels.first
//            }
//            .store(in: &cancellables)
    }

    func playButtonText() -> String {

        if item.unaired {
            return L10n.unaired
        }

        if item.missing {
            return L10n.missing
        }

        if let itemProgressString = item.progress {
            return itemProgressString
        }

        return L10n.play
    }

    func getSimilarItems() {
        LibraryAPI.getSimilarItems(
            itemId: item.id!,
            userId: SessionManager.main.currentLogin.user.id,
            limit: 20,
            fields: ItemFields.allCases
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            self?.similarItems = response.items ?? []
        })
        .store(in: &cancellables)
    }

    func getSpecialFeatures() {
        UserLibraryAPI.getSpecialFeatures(
            userId: SessionManager.main.currentLogin.user.id,
            itemId: item.id!
        )
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] items in
            self?.specialFeatures = items.filter { $0.specialFeatureType?.isVideo ?? false }
        }
        .store(in: &cancellables)
    }

    func toggleWatchState() {
        let current = isPlayed
        isPlayed.toggle()
        let request: AnyPublisher<UserItemDataDto, Error>

        if current {
            request = PlaystateAPI.markUnplayedItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
        } else {
            request = PlaystateAPI.markPlayedItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
        }

        request
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure:
                    self?.isPlayed = !current
                case .finished: ()
                }
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    func toggleFavoriteState() {
        let current = isFavorited
        isFavorited.toggle()
        let request: AnyPublisher<UserItemDataDto, Error>

        if current {
            request = UserLibraryAPI.unmarkFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
        } else {
            request = UserLibraryAPI.markFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
        }

        request
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure:
                    self?.isFavorited = !current
                case .finished: ()
                }
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }

    // Overridden by subclasses
    func updateItem() {}
}
