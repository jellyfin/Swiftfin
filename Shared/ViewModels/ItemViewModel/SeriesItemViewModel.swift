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

final class SeriesItemViewModel: ItemViewModel {

    @Published
    var seasons: OrderedDictionary<BaseItemDto, OrderedSet<BaseItemDto>> = [:]
    @Published
    var selection: BaseItemDto? = nil

    override init(item: BaseItemDto) {
        super.init(item: item)

//        getSeasons()

        // The server won't have both a next up item
        // and a resume item at the same time, so they
        // control the button first. Also fetch first available
        // item, which may be overwritten by next up or resume.
//        getNextUp()
//        getResumeItem()
//        getFirstAvailableItem()
    }

    // TODO: find season that determined playbutton item is a part of
    override func onRefresh() async throws {

        await MainActor.run {
            self.seasons.removeAll()
            self.selection = nil
        }

        async let nextUp = getNextUp()
        async let resume = getResumeItem()
        async let firstAvailable = getFirstAvailableItem()
        async let seasons = getSeasons()

        if let seriesItem = try await [nextUp, resume].first {
            await MainActor.run {
                self.playButtonItem = seriesItem
            }
        } else if let firstAvailable = try await firstAvailable {
            await MainActor.run {
                self.playButtonItem = firstAvailable
            }
        }

//        let newSeasons: [BaseItemDto: [BaseItemDto]] = try await seasons
//            .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) }
//            .reduce(into: [:]) { partialResult, season in
//                partialResult[season] = []
//            }

        let s = try await seasons

        let newSeasons = s
            .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) }
            .zipped(with: Array(repeating: OrderedSet<BaseItemDto>(), count: s.count))

        await MainActor.run {
            self.seasons.merge(newSeasons) { _, new in new }
            self.selection = s.first
        }

        let episodes = try await episodes(for: s.first!)

        await MainActor.run {
            self.seasons[s.first!]?.append(contentsOf: episodes)
        }
    }

//    override func playButtonText() -> String {
//
//        if item.isUnaired {
//            return L10n.unaired
//        }
//
//        if item.isMissing {
//            return L10n.missing
//        }
//
//        guard let playButtonItem = playButtonItem,
//              let episodeLocator = playButtonItem.seasonEpisodeLabel else { return L10n.play }
//
//        return episodeLocator
//    }

    private func getNextUp() async throws -> BaseItemDto? {

        var parameters = Paths.GetNextUpParameters()
        parameters.fields = .MinimumFields
        parameters.seriesID = item.id
        parameters.userID = userSession.user.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }

    private func getResumeItem() async throws -> BaseItemDto? {

        var parameters = Paths.GetResumeItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 1
        parameters.parentID = item.id

        let request = Paths.getResumeItems(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items?.first
    }

    private func getFirstAvailableItem() async throws -> BaseItemDto? {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.episode]
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.parentID = item.id
        parameters.sortOrder = [.ascending]

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items?.first
    }

//    func select(section: BaseItemDto) {
//        self.menuSelection = section
//
//        if let episodes = menuSections[section] {
//            if episodes.isEmpty {
//                getEpisodesForSeason(section)
//            } else {
//                self.currentItems = episodes
//            }
//        }
//    }

    private func getSeasons() async throws -> [BaseItemDto] {

        var parameters = Paths.GetSeasonsParameters()
        parameters.isMissing = Defaults[.Customization.shouldShowMissingSeasons] ? nil : false
        parameters.userID = userSession.user.id

        let request = Paths.getSeasons(
            seriesID: item.id!,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    // TODO: lazy loading
    private func episodes(for season: BaseItemDto) async throws -> [BaseItemDto] {

        var parameters = Paths.GetEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isMissing = Defaults[.Customization.shouldShowMissingEpisodes] ? nil : false
        parameters.seasonID = season.id
        parameters.userID = userSession.user.id

        let request = Paths.getEpisodes(
            seriesID: item.id!,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
