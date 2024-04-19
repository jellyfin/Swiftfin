//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// TODO: is current program-channel requesting best way to do it?

// Note: section item limit is low so that total channel amount is not too much

final class ProgramsViewModel: ViewModel, Stateful {

    enum ProgramSection: CaseIterable {
        case kids
        case movies
        case news
        case recommended
        case series
        case sports
    }

    // MARK: Action

    enum Action: Equatable {
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    private(set) var kids: [ChannelProgram] = []
    @Published
    private(set) var movies: [ChannelProgram] = []
    @Published
    private(set) var news: [ChannelProgram] = []
    @Published
    private(set) var recommended: [ChannelProgram] = []
    @Published
    private(set) var series: [ChannelProgram] = []
    @Published
    private(set) var sports: [ChannelProgram] = []

    @Published
    final var lastAction: Action? = nil
    @Published
    final var state: State = .initial

    private var programChannels: [BaseItemDto] = []

    private var currentRefreshTask: AnyCancellable?

    var hasNoResults: Bool {
        kids.isEmpty &&
            movies.isEmpty &&
            news.isEmpty &&
            recommended.isEmpty &&
            series.isEmpty &&
            sports.isEmpty
    }

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        case .refresh:
            currentRefreshTask?.cancel()

            currentRefreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let sections = try await getItemSections()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.kids = sections[.kids] ?? []
                        self.movies = sections[.movies] ?? []
                        self.news = sections[.news] ?? []
                        self.recommended = sections[.recommended] ?? []
                        self.series = sections[.series] ?? []
                        self.sports = sections[.sports] ?? []

                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        }
    }

    private func getItemSections() async throws -> [ProgramSection: [ChannelProgram]] {
        try await withThrowingTaskGroup(
            of: (ProgramSection, [BaseItemDto]).self,
            returning: [ProgramSection: [ChannelProgram]].self
        ) { group in

            // sections
            for section in ProgramSection.allCases {
                group.addTask {
                    let items = try await self.getPrograms(for: section)
                    return (section, items)
                }
            }

            // recommended
            group.addTask {
                let items = try await self.getRecommendedPrograms()
                return (ProgramSection.recommended, items)
            }

            var programs: [ProgramSection: [BaseItemDto]] = [:]

            while let items = try await group.next() {
                programs[items.0] = items.1
            }

            // get channels for all programs at once to
            // avoid going back and forth too much
            let channels = try await Set(self.getChannels(for: programs.values.flatMap { $0 }))

            let result: [ProgramSection: [ChannelProgram]] = programs.mapValues { programs in
                programs.compactMap { program in
                    guard let channel = channels.first(where: { channel in channel.id == program.channelID }) else { return nil }
                    return ChannelProgram(channel: channel, programs: [program])
                }
            }

            return result
        }
    }

    private func getRecommendedPrograms() async throws -> [BaseItemDto] {

        var parameters = Paths.GetRecommendedProgramsParameters()
        parameters.fields = .MinimumFields
            .appending(.channelInfo)
        parameters.isAiring = true
        parameters.limit = 10
        parameters.userID = userSession.user.id

        let request = Paths.getRecommendedPrograms(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getPrograms(for section: ProgramSection) async throws -> [BaseItemDto] {

        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.fields = .MinimumFields
            .appending(.channelInfo)
        parameters.hasAired = false
        parameters.limit = 10
        parameters.userID = userSession.user.id

        parameters.isKids = section == .kids
        parameters.isMovie = section == .movies
        parameters.isNews = section == .news
        parameters.isSeries = section == .series
        parameters.isSports = section == .sports

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getChannels(for programs: [BaseItemDto]) async throws -> [BaseItemDto] {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.ids = programs.compactMap(\.channelID)

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
