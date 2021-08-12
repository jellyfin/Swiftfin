//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import CombineExt
import Foundation
import JellyfinAPI

final class LibrarySearchViewModel: ViewModel {

    @Published var supportedItemTypeList = [ItemType]()

    @Published var selectedItemType: ItemType = .movie

    @Published var movieItems = [BaseItemDto]()
    @Published var showItems = [BaseItemDto]()
    @Published var episodeItems = [BaseItemDto]()

    @Published var suggestions = [BaseItemDto]()

    var searchQuerySubject = CurrentValueSubject<String, Never>("")
    var parentID: String?

    init(parentID: String?) {
        self.parentID = parentID
        super.init()

        searchQuerySubject
            .filter { !$0.isEmpty }
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink(receiveValue: search)
            .store(in: &cancellables)
        setupPublishersForSupportedItemType()

        requestSuggestions()
    }

    func setupPublishersForSupportedItemType() {

        let supportedItemTypeListPublishers = Publishers.CombineLatest3($movieItems, $showItems, $episodeItems)
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .map { arg -> [ItemType] in
                var typeList = [ItemType]()
                if !arg.0.isEmpty {
                    typeList.append(.movie)
                }
                if !arg.1.isEmpty {
                    typeList.append(.series)
                }
                if !arg.2.isEmpty {
                    typeList.append(.episode)
                }
                return typeList
            }

        supportedItemTypeListPublishers
            .assign(to: \.supportedItemTypeList, on: self)
            .store(in: &cancellables)

        supportedItemTypeListPublishers
            .withLatestFrom(supportedItemTypeListPublishers, $selectedItemType)
            .compactMap { typeList, selectedItemType in
                if typeList.contains(selectedItemType) {
                    return selectedItemType
                } else {
                    return typeList.first
                }
            }
            .assign(to: \.selectedItemType, on: self)
            .store(in: &cancellables)
    }

    func requestSuggestions() {
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!,
                                  limit: 20,
                                  recursive: true,
                                  parentId: parentID,
                                  includeItemTypes: ["Movie", "Series"],
                                  sortBy: ["IsFavoriteOrLiked", "Random"],
                                  imageTypeLimit: 0,
                                  enableTotalRecordCount: false,
                                  enableImages: false)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.suggestions = response.items ?? []
            })
            .store(in: &cancellables)
    }

    func search(with query: String) {
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!, limit: 50, recursive: true, searchTerm: query,
                                  sortOrder: [.ascending], parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                  includeItemTypes: [ItemType.movie.rawValue], sortBy: ["SortName"], enableUserData: true, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.movieItems = response.items ?? []
            })
            .store(in: &cancellables)
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!, limit: 50, recursive: true, searchTerm: query,
                                  sortOrder: [.ascending], parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                  includeItemTypes: [ItemType.series.rawValue], sortBy: ["SortName"], enableUserData: true, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.showItems = response.items ?? []
            })
            .store(in: &cancellables)
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!, limit: 50, recursive: true, searchTerm: query,
                                  sortOrder: [.ascending], parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                  includeItemTypes: [ItemType.episode.rawValue], sortBy: ["SortName"], enableUserData: true, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.episodeItems = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
