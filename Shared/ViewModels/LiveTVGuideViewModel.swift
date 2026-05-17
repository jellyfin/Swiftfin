//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
final class LiveTVGuideViewModel: ViewModel {

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    @Published
    private(set) var channels: [ChannelProgram] = []
    @Published
    private(set) var isLoadingNextPage = false
    @Published
    private(set) var maxDate: Date = .now
    @Published
    private(set) var minDate: Date = .now
    @Published
    private(set) var state: State = .initial

    private let channelPageSize = 200
    private let preloadThreshold = 40

    private var channelStartIndex = 0
    private var hasNextChannelPage = true
    private var groupedPrograms: [String?: [BaseItemDto]] = [:]
    private var nextPageTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?

    var hasNoResults: Bool {
        channels.isEmpty
    }

    deinit {
        nextPageTask?.cancel()
        refreshTask?.cancel()
    }

    func refresh() {
        nextPageTask?.cancel()
        refreshTask?.cancel()
        state = .refreshing

        refreshTask = Task { [weak self] in
            guard let self else { return }

            do {
                let guideWindow = makeGuideWindow()
                let programs = try await getPrograms(minDate: guideWindow.minDate, maxDate: guideWindow.maxDate)
                let channelPage = try await getChannelPage(startIndex: 0)

                guard !Task.isCancelled else { return }

                minDate = guideWindow.minDate
                maxDate = guideWindow.maxDate
                groupedPrograms = Dictionary(grouping: programs, by: \.channelID)
                channelStartIndex = channelPage.count
                hasNextChannelPage = channelPage.count == channelPageSize
                channels = channelPrograms(for: channelPage)
                state = .content
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(.init(error.localizedDescription))
            }
        }
    }

    func loadNextPageIfNeeded(currentIndex: Int) {
        guard hasNextChannelPage, !isLoadingNextPage else { return }
        guard channels.count - currentIndex <= preloadThreshold else { return }

        loadNextPage()
    }

    private func loadNextPage() {
        nextPageTask?.cancel()
        isLoadingNextPage = true

        let startIndex = channelStartIndex

        nextPageTask = Task { [weak self] in
            guard let self else { return }

            do {
                let channelPage = try await getChannelPage(startIndex: startIndex)
                guard !Task.isCancelled else { return }

                channelStartIndex += channelPage.count
                hasNextChannelPage = channelPage.count == channelPageSize
                channels = channelPrograms(for: channels.map(\.channel) + channelPage)
                isLoadingNextPage = false
            } catch {
                guard !Task.isCancelled else { return }
                isLoadingNextPage = false
            }
        }
    }

    private func makeGuideWindow() -> (minDate: Date, maxDate: Date) {
        let minDate = Calendar.current.date(byAdding: .minute, value: -30, to: .now) ?? .now
        let maxDate = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now
        return (minDate, maxDate)
    }

    private func getChannelPage(startIndex: Int) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = channelPageSize
        parameters.startIndex = startIndex

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getPrograms(minDate: Date, maxDate: Date) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.limit = 2000
        parameters.maxStartDate = maxDate
        parameters.minEndDate = minDate
        parameters.sortBy = [ItemSortBy.startDate]

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func channelPrograms(for channels: [BaseItemDto]) -> [ChannelProgram] {
        channels.map { channel in
            ChannelProgram(
                channel: channel,
                programs: (groupedPrograms[channel.id] ?? [])
                    .sorted(using: \.startDate)
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.channel.channelNumberValue, rhs.channel.channelNumberValue) {
            case let (lhsNumber?, rhsNumber?) where lhsNumber != rhsNumber:
                lhsNumber < rhsNumber
            case (_?, nil):
                true
            case (nil, _?):
                false
            default:
                lhs.channel.displayTitle.localizedStandardCompare(rhs.channel.displayTitle) == .orderedAscending
            }
        }
    }
}

private extension BaseItemDto {

    var channelNumberValue: Double? {
        guard let number else { return nil }
        return Double(number)
    }
}
