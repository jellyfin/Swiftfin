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

final class SeasonItemViewModel: ItemViewModel, EpisodesRowManager {

	@RouterObject
	var itemRouter: ItemCoordinator.Router?
	@Published
	var episodes: [BaseItemDto] = []
	@Published
	var seriesItem: BaseItemDto?
	@Published
	var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] = [:]
	@Published
	var selectedSeason: BaseItemDto?

	override init(item: BaseItemDto) {
		super.init(item: item)

		getSeriesItem()
		selectedSeason = item
		retrieveSeasons()
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

//	private func requestEpisodes() {
//		LogManager.shared.log
//			.debug("Getting episodes in season \(item.id!) (\(item.name!)) of show \(item.seriesId!) (\(item.seriesName!))")
//		TvShowsAPI.getEpisodes(seriesId: item.seriesId ?? "", userId: SessionManager.main.currentLogin.user.id,
//		                       fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
//		                       seasonId: item.id ?? "")
//			.trackActivity(loading)
//			.sink(receiveCompletion: { [weak self] completion in
//				self?.handleAPIRequestError(completion: completion)
//			}, receiveValue: { [weak self] response in
//				self?.episodes = response.items ?? []
//				LogManager.shared.log.debug("Retrieved \(String(self?.episodes.count ?? 0)) episodes")
//
//				self?.setNextUpInSeason()
//			})
//			.store(in: &cancellables)
//	}

	// Sets the play button item to the "Next up" in the season based upon
	//     the watched status of episodes in the season.
	// Default to the first episode of the season if all have been watched.
//	private func setNextUpInSeason() {
//		guard !item.missing else { return }
//		guard !episodes.isEmpty else { return }
//
//		var firstUnwatchedSearch: BaseItemDto?
//
//		for episode in episodes {
//			guard let played = episode.userData?.played else { continue }
//			if !played {
//				firstUnwatchedSearch = episode
//				break
//			}
//		}
//
//		if let firstUnwatched = firstUnwatchedSearch {
//			playButtonItem = firstUnwatched
//		} else {
//			guard let firstEpisode = episodes.first else { return }
//			playButtonItem = firstEpisode
//		}
//	}

	private func getSeriesItem() {
		guard let seriesID = item.seriesId else { return }
		UserLibraryAPI.getItem(userId: SessionManager.main.currentLogin.user.id,
		                       itemId: seriesID)
			.trackActivity(loading)
			.sink { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			} receiveValue: { [weak self] seriesItem in
				self?.seriesItem = seriesItem
			}
			.store(in: &cancellables)
	}
}
