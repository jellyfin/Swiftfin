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
import Stinsen

final class EpisodeItemViewModel: ItemViewModel, EpisodesRowManager {

	@RouterObject
	var itemRouter: ItemCoordinator.Router?
	@Published
	var series: BaseItemDto?
	@Published
	var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] = [:]
	@Published
	var selectedSeason: BaseItemDto?

	override init(item: BaseItemDto) {
		super.init(item: item)

		getEpisodeSeries()
		retrieveSeasons()
	}

	override func getItemDisplayName() -> String {
		guard let episodeLocator = item.getEpisodeLocator() else { return item.name ?? "" }
		return "\(episodeLocator)\n\(item.name ?? "")"
	}

	func getEpisodeSeries() {
		guard let id = item.seriesId else { return }
		UserLibraryAPI.getItem(userId: SessionManager.main.currentLogin.user.id, itemId: id)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] item in
				self?.series = item
			})
			.store(in: &cancellables)
	}

	override func updateItem() {
		ItemsAPI.getItems(userId: SessionManager.main.currentLogin.user.id,
		                  limit: 1,
		                  fields: [
		                  	.primaryImageAspectRatio,
		                  	.seriesPrimaryImage,
		                  	.seasonUserData,
		                  	.overview,
		                  	.genres,
		                  	.people,
		                  	.chapters,
		                  ],
		                  enableUserData: true,
		                  ids: [item.id ?? ""])
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { response in
				if let item = response.items?.first {
					self.item = item
					self.playButtonItem = item
				}
			}
			.store(in: &cancellables)
	}
}
