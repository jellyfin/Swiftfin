//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import UIKit

class ItemViewModel: ViewModel {

	@Published
	var item: BaseItemDto
	@Published
	var playButtonItem: BaseItemDto? {
		didSet {
			if let playButtonItem = playButtonItem {
				refreshItemVideoPlayerViewModel(for: playButtonItem)
			}
		}
	}

	@Published
	var similarItems: [BaseItemDto] = []
	@Published
	var isWatched = false
	@Published
	var isFavorited = false
	@Published
	var informationItems: [BaseItemDto.ItemDetail]
	@Published
	var mediaItems: [BaseItemDto.ItemDetail]
	var itemVideoPlayerViewModel: VideoPlayerViewModel?

	init(item: BaseItemDto) {
		self.item = item

		switch item.itemType {
		case .episode, .movie:
			if !item.missing && !item.unaired {
				self.playButtonItem = item
			}
		default: ()
		}

		informationItems = item.createInformationItems()
		mediaItems = item.createMediaItems()

		isFavorited = item.userData?.isFavorite ?? false
		isWatched = item.userData?.played ?? false
		super.init()

		getSimilarItems()

		SwiftfinNotificationCenter.main.addObserver(self,
		                                            selector: #selector(receivedStopReport(_:)),
		                                            name: SwiftfinNotificationCenter.Keys.didSendStopReport,
		                                            object: nil)

		refreshItemVideoPlayerViewModel(for: item)
	}

	@objc
	private func receivedStopReport(_ notification: NSNotification) {
		guard let itemID = notification.object as? String else { return }

		if itemID == item.id {
			updateItem()
		} else {
			// Remove if necessary. Note that this cannot be in deinit as
			// holding as an observer won't allow the object to be deinit-ed
			SwiftfinNotificationCenter.main.removeObserver(self)
		}
	}

	func refreshItemVideoPlayerViewModel(for item: BaseItemDto) {
		guard item.itemType == .episode || item.itemType == .movie else { return }
		guard !item.missing, !item.unaired else { return }

		item.createVideoPlayerViewModel()
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { videoPlayerViewModel in
				self.itemVideoPlayerViewModel = videoPlayerViewModel
				self.mediaItems = videoPlayerViewModel.item.createMediaItems()
			}
			.store(in: &cancellables)
	}

	func playButtonText() -> String {

		if item.unaired {
			return L10n.unaired
		}

		if item.missing {
			return L10n.missing
		}

		if let itemProgressString = item.getItemProgressString() {
			return itemProgressString
		}

		return L10n.play
	}

	func getItemDisplayName() -> String {
		item.name ?? ""
	}

	func shouldDisplayRuntime() -> Bool {
		true
	}

	func getSimilarItems() {
		LibraryAPI.getSimilarItems(itemId: item.id!,
		                           userId: SessionManager.main.currentLogin.user.id,
		                           limit: 10,
		                           fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people])
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.similarItems = response.items ?? []
			})
			.store(in: &cancellables)
	}

	func updateWatchState() {
		if isWatched {
			PlaystateAPI.markUnplayedItem(userId: SessionManager.main.currentLogin.user.id,
			                              itemId: item.id!)
				.trackActivity(loading)
				.sink(receiveCompletion: { [weak self] completion in
					self?.handleAPIRequestError(completion: completion)
				}, receiveValue: { [weak self] _ in
					self?.isWatched = false
				})
				.store(in: &cancellables)
		} else {
			PlaystateAPI.markPlayedItem(userId: SessionManager.main.currentLogin.user.id,
			                            itemId: item.id!)
				.trackActivity(loading)
				.sink(receiveCompletion: { [weak self] completion in
					self?.handleAPIRequestError(completion: completion)
				}, receiveValue: { [weak self] _ in
					self?.isWatched = true
				})
				.store(in: &cancellables)
		}
	}

	func updateFavoriteState() {
		if isFavorited {
			UserLibraryAPI.unmarkFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
				.trackActivity(loading)
				.sink(receiveCompletion: { [weak self] completion in
					self?.handleAPIRequestError(completion: completion)
				}, receiveValue: { [weak self] _ in
					self?.isFavorited = false
				})
				.store(in: &cancellables)
		} else {
			UserLibraryAPI.markFavoriteItem(userId: SessionManager.main.currentLogin.user.id, itemId: item.id!)
				.trackActivity(loading)
				.sink(receiveCompletion: { [weak self] completion in
					self?.handleAPIRequestError(completion: completion)
				}, receiveValue: { [weak self] _ in
					self?.isFavorited = true
				})
				.store(in: &cancellables)
		}
	}

	// Overridden by subclasses
	func updateItem() {}
}
