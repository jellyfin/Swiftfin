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

final class GuideViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case error(ErrorMessage)
        case refresh
        case loadMore
        case select(day: Date)
    }

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    private static let pageSize = 50
    private static let dayCount = 7

    @Published
    private(set) var channels: [ChannelProgram] = []
    @Published
    private(set) var selectedDay: Date = Calendar.current.startOfDay(for: .now)
    @Published
    private(set) var isLoadingMore = false
    @Published
    var state: State = .initial

    let availableDays: [Date]

    var dayStart: Date {
        selectedDay
    }

    var dayEnd: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? selectedDay
    }

    private var hasMore = true
    private var refreshTask: AnyCancellable?
    private var pageTask: AnyCancellable?

    override init() {
        let today = Calendar.current.startOfDay(for: .now)

        self.availableDays = (0 ..< Self.dayCount).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }

        super.init()
    }

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        case let .select(day):
            guard day != selectedDay else { return state }
            selectedDay = Calendar.current.startOfDay(for: day)
            return respond(to: .refresh)
        case .refresh:
            refreshTask?.cancel()
            pageTask?.cancel()
            hasMore = true
            isLoadingMore = false

            refreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let page = try await getChannelsPage(startIndex: 0)

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.channels = page
                        self.hasMore = page.count >= Self.pageSize
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
        case .loadMore:
            guard state == .content, hasMore, !isLoadingMore else { return state }

            isLoadingMore = true
            let startIndex = channels.count

            pageTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let page = try await getChannelsPage(startIndex: startIndex)

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.channels.append(contentsOf: page)
                        self.hasMore = page.count >= Self.pageSize
                        self.isLoadingMore = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoadingMore = false
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    private func getChannelsPage(startIndex: Int) async throws -> [ChannelProgram] {
        let userSession = try requireUserSession()

        var channelParameters = Paths.GetLiveTvChannelsParameters()
        channelParameters.fields = .MinimumFields
        channelParameters.limit = Self.pageSize
        channelParameters.startIndex = startIndex
        channelParameters.sortBy = [.sortName]
        channelParameters.userID = userSession.user.id

        let channelRequest = Paths.getLiveTvChannels(parameters: channelParameters)
        let channelResponse = try await send(channelRequest)

        let channels = channelResponse.value.items ?? []

        guard channels.isNotEmpty else { return [] }

        var programParameters = Paths.GetLiveTvProgramsParameters()
        programParameters.channelIDs = channels.compactMap(\.id)
        programParameters.fields = .MinimumFields.appending(.channelInfo)
        programParameters.maxStartDate = dayEnd
        programParameters.minEndDate = dayStart
        programParameters.sortBy = [.startDate]
        programParameters.userID = userSession.user.id

        let programRequest = Paths.getLiveTvPrograms(parameters: programParameters)
        let programResponse = try await send(programRequest)

        let groupedPrograms = Dictionary(grouping: programResponse.value.items ?? []) { $0.channelID }

        return channels.map { channel in
            ChannelProgram(
                channel: channel,
                programs: (groupedPrograms[channel.id] ?? []).sorted(using: \.startDate)
            )
        }
    }
}
