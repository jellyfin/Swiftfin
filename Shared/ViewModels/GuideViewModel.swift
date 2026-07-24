//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Algorithms
import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI

@MainActor
@Stateful
final class GuideViewModel: ViewModel {

    @CasePathable
    enum Action {
        case getNextPage(channels: IdentifiedArrayOf<BaseItemDto>)
        case refresh(channels: IdentifiedArrayOf<BaseItemDto>)
        case setDate(date: Date)

        var transition: Transition {
            switch self {
            case .getNextPage:
                .background(.refreshing)
            case .refresh:
                .to(.refreshing, then: .content)
            case .setDate:
                .none
            }
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    private(set) var entries: [String: [LiveTVGuideProgram.Positioned]] = [:]
    @Published
    private(set) var now: Date = .now
    @Published
    var selectedChannelID: String?
    @Published
    private(set) var startDate: Date

    private let layout = LiveTVGuideLayout()

    let availableDates: [Date]
    let hours: Int
    let proxy = LiveTVGuideProxy()

    private let batchSize = 50
    private let lookback: TimeInterval
    private var channels: IdentifiedArrayOf<BaseItemDto> = []
    private var fetchedChannelIDs: Set<String> = []

    init(
        hours: Int = 12,
        lookback: TimeInterval = 3600
    ) {
        self.hours = hours
        self.lookback = lookback

        let today = Calendar.current.startOfDay(for: .now)
        self.availableDates = (0 ..< 7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }
        self.startDate = .now

        super.init()

        self.startDate = defaultStartDate()

        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                Task { @MainActor in
                    self?.now = date
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage(_ channels: IdentifiedArrayOf<BaseItemDto>) async throws {
        try await updatePrograms(with: channels)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh(_ channels: IdentifiedArrayOf<BaseItemDto>) async throws {
        try await updatePrograms(with: channels)
    }

    private func updatePrograms(with channels: IdentifiedArrayOf<BaseItemDto>) async throws {
        self.channels = channels

        let channelIDs = channels
            .compactMap(\.id)
            .filter { !fetchedChannelIDs.contains($0) }

        guard channelIDs.isNotEmpty else { return }

        fetchedChannelIDs.formUnion(channelIDs)

        let requestStartDate = startDate
        let requestEndDate = endDate

        do {
            let programs = try await getPrograms(
                channelIDs: channelIDs,
                startDate: requestStartDate,
                endDate: requestEndDate
            )

            guard startDate == requestStartDate else { return }

            let newEntries = Dictionary(grouping: programs.filter { $0.channelID != nil }) { $0.channelID ?? "" }
                .mapValues { programs in
                    LiveTVGuideProgram.positioned(
                        from: programs,
                        startDate: requestStartDate,
                        endDate: requestEndDate,
                        layout: layout
                    )
                }

            entries.merge(newEntries) { _, new in new }
        } catch {
            fetchedChannelIDs.subtract(channelIDs)
            throw error
        }
    }

    @Function(\Action.Cases.setDate)
    private func _setDate(_ date: Date) {
        let calendar = Calendar.current
        let newStartDate = calendar.isDateInToday(date)
            ? defaultStartDate()
            : calendar.startOfDay(for: date)

        guard newStartDate != startDate else { return }

        startDate = newStartDate
        entries.removeAll()
        fetchedChannelIDs.removeAll()
        proxy.reset()
        refresh(channels: channels)
    }

    private func defaultStartDate() -> Date {
        let current = Date.now
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: current)
        let minute = calendar.component(.minute, from: current)
        let halfHour = calendar.date(bySettingHour: hour, minute: minute - minute % 30, second: 0, of: current) ?? current

        return halfHour.addingTimeInterval(-lookback)
    }

    var endDate: Date {
        let spanEnd = startDate.addingTimeInterval(TimeInterval(hours) * 3600)

        guard let nextDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: startDate)
        ) else { return spanEnd }

        return max(spanEnd, nextDay)
    }

    private func getPrograms(
        channelIDs: [String],
        startDate: Date,
        endDate: Date
    ) async throws -> [BaseItemDto] {
        let userID = try authenticatedUser.id

        return try await withThrowingTaskGroup(of: [BaseItemDto].self) { group in
            for batch in channelIDs.chunks(ofCount: batchSize) {
                group.addTask {
                    var parameters = Paths.GetLiveTvProgramsParameters()
                    parameters.channelIDs = Array(batch)
                    parameters.maxStartDate = endDate
                    parameters.minEndDate = startDate
                    parameters.sortBy = [.startDate]
                    parameters.userID = userID

                    let request = Paths.getLiveTvPrograms(parameters: parameters)
                    let response = try await self.send(request)

                    return response.value.items ?? []
                }
            }

            return try await group.reduce(into: []) {
                $0.append(contentsOf: $1)
            }
        }
    }
}
