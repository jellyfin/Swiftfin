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

        getSeasons()

        // The server won't have both a next up item
        // and a resume item at the same time, so they
        // control the button first. Also fetch first available
        // item, which may be overwritten by next up or resume.
        getNextUp()
        getResumeItem()
        getFirstAvailableItem()
    }

    override func playButtonText() -> String {

        if item.unaired {
            return L10n.unaired
        }

        if item.missing {
            return L10n.missing
        }

        guard let playButtonItem = playButtonItem,
              let episodeLocator = playButtonItem.seasonEpisodeLocator else { return L10n.play }

        return episodeLocator
    }

    private func getNextUp() {
        logger.debug("Getting next up for show \(self.item.id!) (\(self.item.name!))")
        TvShowsAPI.getNextUp(
            userId: SessionManager.main.currentLogin.user.id,
            seriesId: self.item.id!,
            enableUserData: true
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            if let nextUpItem = response.items?.first, !nextUpItem.unaired, !nextUpItem.missing {
                self?.playButtonItem = nextUpItem

                if let seasonID = nextUpItem.seasonId {
                    self?.select(seasonID: seasonID)
                }
            }
        })
        .store(in: &cancellables)
    }

    private func getResumeItem() {
        ItemsAPI.getResumeItems(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 1,
            parentId: item.id
        )
        .trackActivity(loading)
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            if let firstItem = response.items?.first {
                self?.playButtonItem = firstItem

                if let seasonID = firstItem.seasonId {
                    self?.select(seasonID: seasonID)
                }
            }
        }
        .store(in: &cancellables)
    }

    private func getFirstAvailableItem() {
        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 2,
            recursive: true,
            sortOrder: [.ascending],
            parentId: item.id,
            includeItemTypes: [.episode]
        )
        .trackActivity(loading)
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            if let firstItem = response.items?.first {
                if self?.playButtonItem == nil {
                    // If other calls finish after this, it will be overwritten
                    self?.playButtonItem = firstItem

                    if let seasonID = firstItem.seasonId {
                        self?.select(seasonID: seasonID)
                    }
                }
            }
        }
        .store(in: &cancellables)
    }

    func getRunYears() -> String {
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
}
