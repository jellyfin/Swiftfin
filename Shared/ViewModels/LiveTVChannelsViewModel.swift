//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import Get
import JellyfinAPI

extension Notification.Name {
    static let livePlayerDismissed = Notification.Name("livePlayerDismissed")
}

final class LiveTVChannelsViewModel: PagingLibraryViewModel<LiveTVChannelProgram> {

    @Published
    var channels: [BaseItemDto] = []
    @Published
    var channelPrograms: [LiveTVChannelProgram] = []

    private var programs = [BaseItemDto]()
    private var channelProgramsList = [BaseItemDto: [BaseItemDto]]()
    private var timer: Timer?

    var timeFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "h:mm"
        return df
    }

    init() {
        super.init()
    }

    override func get(page: Int) async throws -> [LiveTVChannelProgram] {
        try await getChannelPrograms()
    }

    deinit {
        stopScheduleCheckTimer()
    }

    private func getChannelPrograms() async throws -> [LiveTVChannelProgram] {
        let _ = try await getGuideInfo()
        let channelsResponse = try await getChannels()
        guard let channels = channelsResponse.value.items, !channels.isEmpty else {
            return []
        }
        let programsResponse = try await getPrograms(channelIds: channels.compactMap(\.id))
        let fetchedPrograms = programsResponse.value.items ?? []
        await MainActor.run {
            self.programs.append(contentsOf: fetchedPrograms)
        }
        var newChannelPrograms = [LiveTVChannelProgram]()
        let now = Date()
        for channel in channels {
            let prgs = programs.filter { item in
                item.channelID == channel.id
            }

            var currentPrg: BaseItemDto?
            for prg in prgs {
                if let startDate = prg.startDate,
                   let endDate = prg.endDate,
                   now.timeIntervalSinceReferenceDate > startDate.timeIntervalSinceReferenceDate &&
                   now.timeIntervalSinceReferenceDate < endDate.timeIntervalSinceReferenceDate
                {
                    currentPrg = prg
                }
            }

            newChannelPrograms.append(LiveTVChannelProgram(channel: channel, currentProgram: currentPrg, programs: prgs))
        }

        return newChannelPrograms
    }

    private func getGuideInfo() async throws -> Response<GuideInfo> {
        let request = Paths.getGuideInfo
        return try await userSession.client.send(request)
    }

    func getChannels() async throws -> Response<BaseItemDtoQueryResult> {
        let parameters = Paths.GetLiveTvChannelsParameters(
            userID: userSession.user.id,
            startIndex: currentPage * pageSize,
            limit: pageSize,
            enableImageTypes: [.primary],
            fields: ItemFields.MinimumFields,
            enableUserData: false,
            enableFavoriteSorting: true
        )
        let request = Paths.getLiveTvChannels(parameters: parameters)
        return try await userSession.client.send(request)
    }

    private func getPrograms(channelIds: [String]) async throws -> Response<BaseItemDtoQueryResult> {
        let minEndDate = Date.now.addComponentsToDate(hours: -1)
        let maxStartDate = minEndDate.addComponentsToDate(hours: 6)
        let parameters = Paths.GetLiveTvProgramsParameters(
            channelIDs: channelIds,
            userID: userSession.user.id,
            maxStartDate: maxStartDate,
            minEndDate: minEndDate,
            sortBy: ["StartDate"]
        )
        let request = Paths.getLiveTvPrograms(parameters: parameters)
        return try await userSession.client.send(request)
    }

    func startScheduleCheckTimer() {
        let date = Date()
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute], from: date)
        // Run every minute
        guard let minute = components.minute else { return }
        components.second = 0
        components.minute = minute + (1 - (minute % 1))
        guard let nextMinute = calendar.date(from: components) else { return }
        if let existingTimer = timer {
            existingTimer.invalidate()
        }
        timer = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.logger.debug("LiveTVChannels schedule check...")

            Task {
                await MainActor.run {
                    let channelProgramsCopy = self.channelPrograms
                    var refreshedChannelPrograms: [LiveTVChannelProgram] = []
                    for channelProgram in channelProgramsCopy {
                        var currentPrg: BaseItemDto?
                        let now = Date()
                        for prg in channelProgram.programs {
                            if let startDate = prg.startDate,
                               let endDate = prg.endDate,
                               now.timeIntervalSinceReferenceDate > startDate.timeIntervalSinceReferenceDate &&
                               now.timeIntervalSinceReferenceDate < endDate.timeIntervalSinceReferenceDate
                            {
                                currentPrg = prg
                            }
                        }

                        refreshedChannelPrograms
                            .append(LiveTVChannelProgram(
                                channel: channelProgram.channel,
                                currentProgram: currentPrg,
                                programs: channelProgram.programs
                            ))
                    }
                    self.channelPrograms = refreshedChannelPrograms
                }
            }
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .default)
        }
    }

    func stopScheduleCheckTimer() {
        timer?.invalidate()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Date {
    func addComponentsToDate(seconds sec: Int? = nil, minutes min: Int? = nil, hours hrs: Int? = nil, days d: Int? = nil) -> Date {
        var dc = DateComponents()
        if let sec = sec {
            dc.second = sec
        }
        if let min = min {
            dc.minute = min
        }
        if let hrs = hrs {
            dc.hour = hrs
        }
        if let d = d {
            dc.day = d
        }
        return Calendar.current.date(byAdding: dc, to: self)!
    }

    func midnightUTCDate() -> Date {
        var dc: DateComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        dc.nanosecond = 0
        dc.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar.current.date(from: dc)!
    }
}
