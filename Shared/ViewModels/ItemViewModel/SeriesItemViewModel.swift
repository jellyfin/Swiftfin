//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

final class SeriesItemViewModel: ItemViewModel, EpisodesRowManager {

	@Published
	var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] = [:]
	@Published
	var selectedSeason: BaseItemDto?

	override init(item: BaseItemDto) {
		super.init(item: item)

		getNextUp()
		getSeasons()
	}

	override func playButtonText() -> String {

		if item.unaired {
			return L10n.unaired
		}

		if item.missing {
			return L10n.missing
		}

		guard let playButtonItem = playButtonItem, let episodeLocator = playButtonItem.getEpisodeLocator() else { return L10n.play }
		return episodeLocator
	}

	override func shouldDisplayRuntime() -> Bool {
		false
	}

	private func getNextUp() {

		LogManager.log.debug("Getting next up for show \(self.item.id!) (\(self.item.name!))")
		TvShowsAPI.getNextUp(userId: SessionManager.main.currentLogin.user.id,
		                     fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                     seriesId: self.item.id!,
		                     enableUserData: true)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				if let nextUpItem = response.items?.first, !nextUpItem.unaired, !nextUpItem.missing {
					self?.playButtonItem = nextUpItem
				}
			})
			.store(in: &cancellables)
	}
}
