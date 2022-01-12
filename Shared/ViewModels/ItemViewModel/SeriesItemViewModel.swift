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

final class SeriesItemViewModel: ItemViewModel {

	@Published
	var seasons: [BaseItemDto] = []

	override init(item: BaseItemDto) {
		super.init(item: item)

		requestSeasons()
		getNextUp()
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

		LogManager.shared.log.debug("Getting next up for show \(self.item.id!) (\(self.item.name!))")
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

	private func getRunYears() -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy"

		var startYear: String?
		var endYear: String?

		if item.premiereDate != nil {
			startYear = dateFormatter.string(from: item.premiereDate!)
		}

		if item.endDate != nil {
			endYear = dateFormatter.string(from: item.endDate!)
		}

		return "\(startYear ?? L10n.unknown) - \(endYear ?? L10n.present)"
	}

	private func requestSeasons() {
		LogManager.shared.log.debug("Getting seasons of show \(self.item.id!) (\(self.item.name!))")
		TvShowsAPI.getSeasons(seriesId: item.id ?? "", userId: SessionManager.main.currentLogin.user.id,
		                      fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
		                      isMissing: Defaults[.shouldShowMissingSeasons] ? nil : false,
		                      enableUserData: true)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				self?.seasons = response.items ?? []
				LogManager.shared.log.debug("Retrieved \(String(self?.seasons.count ?? 0)) seasons")
			})
			.store(in: &cancellables)
	}
}
