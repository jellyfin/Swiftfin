//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

// TODO: use OrderedDictionary

final class SeriesItemViewModel: ItemViewModel {

    @Published
    var menuSelection: BaseItemDto?
    @Published
    var currentItems: OrderedSet<BaseItemDto> = []

    var menuSections: [BaseItemDto: OrderedSet<BaseItemDto>]
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

        if item.isUnaired {
            return L10n.unaired
        }

        if item.isMissing {
            return L10n.missing
        }

        guard let playButtonItem = playButtonItem,
              let episodeLocator = playButtonItem.seasonEpisodeLabel else { return L10n.play }

        return episodeLocator
    }

    private func getNextUp() {
        Task {
            let parameters = Paths.GetNextUpParameters(
                userID: userSession.user.id,
                fields: .MinimumFields,
                seriesID: item.id,
                enableUserData: true
            )
            let request = Paths.getNextUp(parameters: parameters)
            let response = try await userSession.client.send(request)

            if let item = response.value.items?.first, !item.isMissing {
                await MainActor.run {
                    self.playButtonItem = item
                }
            }
        }
    }

    private func getResumeItem() {
        Task {
            let parameters = Paths.GetResumeItemsParameters(
                limit: 1,
                parentID: item.id,
                fields: .MinimumFields
            )
            let request = Paths.getResumeItems(userID: userSession.user.id, parameters: parameters)
            let response = try await userSession.client.send(request)

            if let item = response.value.items?.first {
                await MainActor.run {
                    self.playButtonItem = item
                }
            }
        }
    }

    private func getFirstAvailableItem() {
        Task {
            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                limit: 1,
                isRecursive: true,
                sortOrder: [.ascending],
                parentID: item.id,
                fields: .MinimumFields,
                includeItemTypes: [.episode]
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            if let item = response.value.items?.first {
                if self.playButtonItem == nil {
                    await MainActor.run {
                        self.playButtonItem = item
                    }
                }
            }
        }
    }

    func select(section: BaseItemDto) {
        self.menuSelection = section

        if let episodes = menuSections[section] {
            if episodes.isEmpty {
                getEpisodesForSeason(section)
            } else {
                self.currentItems = episodes
            }
        }
    }

    private func getSeasons() {
        Task {
            let parameters = Paths.GetSeasonsParameters(
                userID: userSession.user.id,
                isMissing: Defaults[.Customization.shouldShowMissingSeasons] ? nil : false
            )
            let request = Paths.getSeasons(seriesID: item.id!, parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let seasons = response.value.items else { return }

            await MainActor.run {
                for season in seasons {
                    self.menuSections[season] = []
                }
            }

            if let firstSeason = seasons.first {
                self.getEpisodesForSeason(firstSeason)
                await MainActor.run {
                    self.menuSelection = firstSeason
                }
            }
        }
    }

    // TODO: implement lazy loading
    private func getEpisodesForSeason(_ season: BaseItemDto) {
        Task {
            let parameters = Paths.GetEpisodesParameters(
                userID: userSession.user.id,
                fields: .MinimumFields,
                seasonID: season.id!,
                isMissing: Defaults[.Customization.shouldShowMissingEpisodes] ? nil : false,
                enableUserData: true
            )
            let request = Paths.getEpisodes(seriesID: item.id!, parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                if let items = response.value.items {
                    let newItems = OrderedSet(items)
                    self.menuSections[season] = newItems
                    self.currentItems = newItems
                }
            }
        }
    }
}
