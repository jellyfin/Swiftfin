//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

protocol EpisodesRowManager: ViewModel {
	var item: BaseItemDto { get }
	var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] { get set }
	var selectedSeason: BaseItemDto? { get set }
	func retrieveSeasons()
	func retrieveEpisodesForSeason(_ season: BaseItemDto)
	func select(season: BaseItemDto)
}

extension EpisodesRowManager {

	// Also retrieves the current season episodes if available
	func retrieveSeasons() {
		TvShowsAPI.getSeasons(seriesId: item.seriesId ?? "",
		                      userId: SessionManager.main.currentLogin.user.id,
		                      isMissing: Defaults[.shouldShowMissingSeasons] ? nil : false)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { response in
				let seasons = response.items ?? []
				seasons.forEach { season in
					self.seasonsEpisodes[season] = []

					if season.id == self.item.seasonId ?? "" {
						self.selectedSeason = season
						self.retrieveEpisodesForSeason(season)
					} else if season.id == self.item.id ?? "" {
						self.selectedSeason = season
						self.retrieveEpisodesForSeason(season)
					}
				}
			}
			.store(in: &cancellables)
	}

	func retrieveEpisodesForSeason(_ season: BaseItemDto) {
		guard let seasonID = season.id else { return }

		TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "",
		                       userId: SessionManager.main.currentLogin.user.id,
		                       fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                       seasonId: seasonID,
		                       isMissing: Defaults[.shouldShowMissingEpisodes] ? nil : false)
			.trackActivity(loading)
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { episodes in
				self.seasonsEpisodes[season] = episodes.items ?? []
			}
			.store(in: &cancellables)
	}

	func select(season: BaseItemDto) {
		self.selectedSeason = season

		if seasonsEpisodes[season]!.isEmpty {
			retrieveEpisodesForSeason(season)
		}
	}
}

final class SingleSeasonEpisodesRowViewModel: ViewModel {

	// TODO: Protocol these viewmodels for generalization instead of Season

	@ObservedObject
	var seasonItemViewModel: SeasonItemViewModel
	@Published
	var episodes: [BaseItemDto]

	init(seasonItemViewModel: SeasonItemViewModel) {
		self.seasonItemViewModel = seasonItemViewModel
		self.episodes = seasonItemViewModel.episodes
		super.init()
	}
}
