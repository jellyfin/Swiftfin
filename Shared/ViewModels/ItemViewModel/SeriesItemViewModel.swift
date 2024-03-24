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
    var seasons: OrderedSet<SeasonItemViewModel> = []

    // TODO: find season that determined playbutton item is a part of
    override func onRefresh() async throws {

        await MainActor.run {
            self.seasons.removeAll()
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

//        let newSeasons = try await seasons

        let newSeasons = try await seasons
            .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) } // sort just in case
            .map(SeasonItemViewModel.init)

        await MainActor.run {
            self.seasons.append(contentsOf: newSeasons)
//            self.seasons.merge(zippedSeasons, uniquingKeysWith: { _, e in e })
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
}
