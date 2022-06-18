//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import CombineExt
import Foundation
import JellyfinAPI
import SwiftUI

final class LibrarySearchViewModel: ViewModel {

	@Published
	var supportedItemTypeList = [ItemType]()

	@Published
	var selectedItemType: ItemType = .movie

	@Published
	var movieItems = [BaseItemDto]()
	@Published
	var showItems = [BaseItemDto]()
	@Published
	var episodeItems = [BaseItemDto]()

	@Published
	var suggestions = [BaseItemDto]()

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
		Publishers.CombineLatest3($movieItems, $showItems, $episodeItems)
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
			.receive(on: DispatchQueue.main)
			.sink(receiveValue: { [weak self] typeList in
				withAnimation {
					self?.supportedItemTypeList = typeList
				}
			})
			.store(in: &cancellables)

		$supportedItemTypeList
			.receive(on: DispatchQueue.main)
			.withLatestFrom($selectedItemType)
			.compactMap { selectedItemType in
				if self.supportedItemTypeList.contains(selectedItemType) {
					return selectedItemType
				} else {
					return self.supportedItemTypeList.first
				}
			}
			.sink(receiveValue: { [weak self] itemType in
				withAnimation {
					self?.selectedItemType = itemType
				}
			})
			.store(in: &cancellables)
	}

	func requestSuggestions() {
		ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id,
		                          limit: 20,
		                          recursive: true,
		                          parentId: parentID,
		                          includeItemTypes: [.movie, .series],
		                          sortBy: ["IsFavoriteOrLiked", "Random"],
		                          imageTypeLimit: 0,
		                          enableTotalRecordCount: false,
		                          enableImages: false)
			.trackActivity(loading)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.suggestions = response.items ?? []
			})
			.store(in: &cancellables)
	}

	func search(with query: String) {
		ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, limit: 50, recursive: true, searchTerm: query,
		                          sortOrder: [.ascending], parentId: parentID,
		                          fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                          includeItemTypes: [.movie], sortBy: ["SortName"], enableUserData: true,
		                          enableImages: true)
			.trackActivity(loading)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.movieItems = response.items ?? []
			})
			.store(in: &cancellables)
		ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, limit: 50, recursive: true, searchTerm: query,
		                          sortOrder: [.ascending], parentId: parentID,
		                          fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                          includeItemTypes: [.series], sortBy: ["SortName"], enableUserData: true,
		                          enableImages: true)
			.trackActivity(loading)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.showItems = response.items ?? []
			})
			.store(in: &cancellables)
		ItemsAPI.getItemsByUserId(userId: SessionManager.main.currentLogin.user.id, limit: 50, recursive: true, searchTerm: query,
		                          sortOrder: [.ascending], parentId: parentID,
		                          fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                          includeItemTypes: [.episode], sortBy: ["SortName"], enableUserData: true,
		                          enableImages: true)
			.trackActivity(loading)
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.episodeItems = response.items ?? []
			})
			.store(in: &cancellables)
	}
}
