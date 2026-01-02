//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

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
        case error(ErrorMessage)
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    @Published
    private(set) var kids: [BaseItemDto] = []
    @Published
    private(set) var movies: [BaseItemDto] = []
    @Published
    private(set) var news: [BaseItemDto] = []
    @Published
    private(set) var recommended: [BaseItemDto] = []
    @Published
    private(set) var series: [BaseItemDto] = []
    @Published
    private(set) var sports: [BaseItemDto] = []

    @Published
    var state: State = .initial

    private var currentRefreshTask: AnyCancellable?

    var hasNoResults: Bool {
        [
            kids,
            movies,
            news,
            recommended,
            series,
            sports,
        ].allSatisfy(\.isEmpty)
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

    private func getItemSections() async throws -> [ProgramSection: [BaseItemDto]] {
        try await withThrowingTaskGroup(
            of: (ProgramSection, [BaseItemDto]).self,
            returning: [ProgramSection: [BaseItemDto]].self
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

            return programs
        }
    }

    private func getRecommendedPrograms() async throws -> [BaseItemDto] {

        var parameters = Paths.GetRecommendedProgramsParameters()
        parameters.fields = .MinimumFields
            .appending(.channelInfo)
        parameters.isAiring = true
        parameters.limit = 20
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
        parameters.limit = 20
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
}
