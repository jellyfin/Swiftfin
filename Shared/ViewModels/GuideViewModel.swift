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
import JellyfinAPI

@MainActor
final class GuideViewModel: ViewModel {

    private static let batchSize = 50
    private static let dayCount = 7

    let scrollProxy = GuideScrollProxy()

    let availableDates: [Date] = {
        let today = Calendar.current.startOfDay(for: .now)

        return (0 ..< GuideViewModel.dayCount).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }
    }()

    @Published
    private(set) var startDate: Date = GuideViewModel.defaultStartDate()
    @Published
    private(set) var now: Date = .now
    @Published
    private(set) var programs: [String: [BaseItemDto]] = [:]
    @Published
    var selectedChannelID: String?

    let hours: Int

    var endDate: Date {
        let spanEnd = startDate.addingTimeInterval(TimeInterval(hours) * 3600)

        guard let nextDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: startDate)
        ) else { return spanEnd }

        return max(spanEnd, nextDay)
    }

    private var fetchedChannelIDs: Set<String> = []

    init(hours: Int = 12) {
        self.hours = hours
        super.init()

        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                Task { @MainActor in
                    self?.now = date
                }
            }
            .store(in: &cancellables)
    }

    func select(date: Date) {
        let calendar = Calendar.current
        let newStartDate = calendar.isDate(date, inSameDayAs: .now)
            ? Self.defaultStartDate()
            : calendar.startOfDay(for: date)

        guard newStartDate != startDate else { return }

        startDate = newStartDate
        programs.removeAll()
        fetchedChannelIDs.removeAll()
        scrollProxy.reset()
    }

    func loadPrograms(for channels: [BaseItemDto]) {
        let channelIDs = channels
            .compactMap(\.id)
            .filter { !fetchedChannelIDs.contains($0) }

        guard channelIDs.isNotEmpty else { return }

        fetchedChannelIDs.formUnion(channelIDs)

        for batch in channelIDs.chunks(ofCount: Self.batchSize) {
            let requestStartDate = startDate

            Task {
                guard startDate == requestStartDate else { return }

                do {
                    let newPrograms = try await fetchPrograms(channelIDs: Array(batch))

                    guard startDate == requestStartDate else { return }

                    programs.merge(newPrograms) { _, new in new }
                } catch {
                    fetchedChannelIDs.subtract(batch)
                }
            }
        }
    }

    private func fetchPrograms(channelIDs: [String]) async throws -> [String: [BaseItemDto]] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channelIDs
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.maxStartDate = endDate
        parameters.minEndDate = startDate
        parameters.sortBy = [.startDate]
        parameters.userID = try authenticatedUser.id

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await send(request)

        let items = (response.value.items ?? [])
            .filter { $0.channelID != nil }

        return Dictionary(grouping: items) { $0.channelID ?? "" }
    }

    private static func defaultStartDate() -> Date {
        let current = Date.now
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: current)
        let minute = calendar.component(.minute, from: current)
        let halfHour = calendar.date(bySettingHour: hour, minute: minute - minute % 30, second: 0, of: current) ?? current

        return halfHour.addingTimeInterval(-3600)
    }
}
