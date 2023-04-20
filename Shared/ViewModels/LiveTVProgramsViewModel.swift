//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class LiveTVProgramsViewModel: ViewModel {

    @Published
    var recommendedItems = [BaseItemDto]()
    @Published
    var seriesItems = [BaseItemDto]()
    @Published
    var movieItems = [BaseItemDto]()
    @Published
    var sportsItems = [BaseItemDto]()
    @Published
    var kidsItems = [BaseItemDto]()
    @Published
    var newsItems = [BaseItemDto]()

    var channels = [String: BaseItemDto]()

    override init() {
        super.init()

//        getChannels()
    }

    func findChannel(id: String) -> BaseItemDto? {
        channels[id]
    }

    private func getChannels() {
        Task {
            let parameters = Paths.GetLiveTvChannelsParameters(
                userID: userSession.user.id,
                startIndex: 0,
                limit: 1000,
                enableImageTypes: [.primary],
                enableUserData: false,
                enableFavoriteSorting: true
            )
            let request = Paths.getLiveTvChannels(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let channels = response.value.items else { return }

            for channel in channels {
                guard let channelID = channel.id else { continue }
                self.channels[channelID] = channel
            }

            getRecommendedPrograms()
            getSeries()
            getMovies()
            getSports()
            getKids()
            getNews()
        }
    }

    private func getRecommendedPrograms() {
        Task {
            let parameters = Paths.GetRecommendedProgramsParameters(
                userID: userSession.user.id,
                limit: 9,
                isAiring: true,
                imageTypeLimit: 1,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio],
                enableTotalRecordCount: false
            )
            let request = Paths.getRecommendedPrograms(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.recommendedItems = items
            }
        }
    }

    private func getSeries() {
        Task {
            let request = Paths.getPrograms(.init(
                enableImageTypes: [.primary, .thumb],
                enableTotalRecordCount: false,
                fields: [.channelInfo, .primaryImageAspectRatio],
                hasAired: false,
                isKids: false,
                isMovie: false,
                isNews: false,
                isSeries: true,
                isSports: false,
                limit: 9,
                userID: userSession.user.id
            ))
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.seriesItems = items
            }
        }
    }

    private func getMovies() {
        Task {
            let request = Paths.getPrograms(.init(
                enableImageTypes: [.primary, .thumb],
                enableTotalRecordCount: false,
                fields: [.channelInfo, .primaryImageAspectRatio],
                hasAired: false,
                isKids: false,
                isMovie: true,
                isNews: false,
                isSeries: false,
                isSports: false,
                limit: 9,
                userID: userSession.user.id
            ))
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.movieItems = items
            }
        }
    }

    private func getSports() {
        Task {
            let request = Paths.getPrograms(.init(
                enableImageTypes: [.primary, .thumb],
                enableTotalRecordCount: false,
                fields: [.channelInfo, .primaryImageAspectRatio],
                hasAired: false,
                isKids: false,
                isMovie: false,
                isNews: false,
                isSeries: false,
                isSports: true,
                limit: 9,
                userID: userSession.user.id
            ))
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.sportsItems = items
            }
        }
    }

    private func getKids() {
        Task {
            let request = Paths.getPrograms(.init(
                enableImageTypes: [.primary, .thumb],
                enableTotalRecordCount: false,
                fields: [.channelInfo, .primaryImageAspectRatio],
                hasAired: false,
                isKids: true,
                isMovie: false,
                isNews: false,
                isSeries: false,
                isSports: false,
                limit: 9,
                userID: userSession.user.id
            ))
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.kidsItems = items
            }
        }
    }

    private func getNews() {
        Task {
            let request = Paths.getPrograms(.init(
                enableImageTypes: [.primary, .thumb],
                enableTotalRecordCount: false,
                fields: [.channelInfo, .primaryImageAspectRatio],
                hasAired: false,
                isKids: false,
                isMovie: false,
                isNews: true,
                isSeries: false,
                isSports: false,
                limit: 9,
                userID: userSession.user.id
            ))
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                self.seriesItems = items
            }
        }
    }
}
