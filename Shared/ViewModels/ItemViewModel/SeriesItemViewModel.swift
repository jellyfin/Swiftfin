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

final class SeriesItemViewModel: ItemViewModel, MenuPosterHStackModel {

    @Published
    var menuSelection: BaseItemDto?
    @Published
    var menuSections: [BaseItemDto: [PosterButtonType<BaseItemDto>]]
    var menuSectionSort: (BaseItemDto, BaseItemDto) -> Bool

    override init(item: BaseItemDto) {
        self.menuSections = [:]
        self.menuSectionSort = { i, j in i.indexNumber ?? -1 < j.indexNumber ?? -1 }

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
                }
            }
        }
        .store(in: &cancellables)
    }

    func select(section: BaseItemDto) {
        self.menuSelection = section

        if let existingItems = menuSections[section] {
            if existingItems.allSatisfy({ $0 == .loading }) {
                getEpisodesForSeason(section)
            } else if existingItems.allSatisfy({ $0 == .noResult }) {
                menuSections[section] = PosterButtonType.loading.random(in: 3 ..< 8)
                getEpisodesForSeason(section)
            }
        } else {
            getEpisodesForSeason(section)
        }
    }

    private func getSeasons() {
        TvShowsAPI.getSeasons(
            seriesId: item.id ?? "",
            userId: SessionManager.main.currentLogin.user.id,
            isMissing: Defaults[.shouldShowMissingSeasons] ? nil : false
        )
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { response in
            guard let seasons = response.items else { return }

            seasons.forEach { season in
                self.menuSections[season] = PosterButtonType.loading.random(in: 3 ..< 8)
            }

            if let firstSeason = seasons.first {
                self.menuSelection = firstSeason
                self.getEpisodesForSeason(firstSeason)
            }
        }
        .store(in: &cancellables)
    }

    private func getEpisodesForSeason(_ season: BaseItemDto) {
        guard let seasonID = season.id else { return }

        TvShowsAPI.getEpisodes(
            seriesId: item.id ?? "",
            userId: SessionManager.main.currentLogin.user.id,
            fields: ItemFields.minimumCases,
            seasonId: seasonID,
            isMissing: Defaults[.shouldShowMissingEpisodes] ? nil : false,
            enableUserData: true
        )
        .trackActivity(loading)
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { response in
            if let items = response.items {
                self.menuSections[season] = items.map { .item($0) }
            } else {
                self.menuSections[season] = [.noResult]
            }
        }
        .store(in: &cancellables)
    }
}
