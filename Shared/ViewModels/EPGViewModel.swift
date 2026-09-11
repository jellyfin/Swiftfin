//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI

@MainActor
@Stateful
final class EPGViewModel: ViewModel {

    @CasePathable
    enum Action {
        case getNextPage
        case refresh(startDate: Date?)
        case setDate(date: Date)

        case _actuallyGetNextPage

        var transition: Transition {
            switch self {
            case .getNextPage:
                .none
            case .refresh:
                .to(.refreshing, then: .content)
                    .onRepeat(.cancel)
            case .setDate:
                .none
            case ._actuallyGetNextPage:
                .background(.gettingNextPage)
            }
        }
    }

    enum BackgroundState {
        case gettingNextPage
    }

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    private struct ChannelPage {
        let channels: IdentifiedArrayOf<BaseItemDto>
        let nextOffset: Int
        let hasNextPage: Bool
    }

    @Published
    private(set) var channels: IdentifiedArrayOf<BaseItemDto> = IdentifiedArray(
        [],
        uniquingIDsWith: { existing, _ in existing }
    )
    @Published
    private(set) var now: Date = .now
    @Published
    private(set) var programs: [String: [ProgramBlock]] = [:]
    private(set) var programsRevision = 0
    @Published
    private(set) var startDate: Date

    private let channelPageSize = defaultPagingLibraryPageSize
    private let channelsLibrary = EPGChannelsLibrary()
    private let minimumDuration: Duration

    private var hasNextChannelPage = true
    private var nextChannelOffset = 0
    private var requestGeneration = 0

    var availableDates: [Date] {
        let today = Calendar.current.startOfDay(for: .now)

        return (0 ..< 7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: today)
        }
    }

    var endDate: Date {
        endDate(startingAt: startDate)
    }

    init(minimumDuration: Duration = .hours(12)) {
        self.minimumDuration = minimumDuration
        self.startDate = .now

        super.init()

        self.startDate = defaultStartDate()

        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                Task { @MainActor in
                    guard let self else { return }

                    self.now = date

                    let startOfToday = Calendar.current.startOfDay(for: date)
                    let guideNeedsRebase = date >= self.endDate || self.startDate < startOfToday

                    if guideNeedsRebase, self.state == .content {
                        self.refresh(startDate: nil)
                    }
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.getNextPage)
    private func _getNextPage() async throws {
        guard state == .content,
              hasNextChannelPage,
              !background.is(.gettingNextPage)
        else { return }

        await _actuallyGetNextPage()
    }

    @Function(\Action.Cases.setDate)
    private func _setDate(_ date: Date) async throws {
        let calendar = Calendar.current
        let newStartDate = calendar.isDateInToday(date)
            ? defaultStartDate()
            : calendar.startOfDay(for: date)

        guard newStartDate != startDate else { return }
        await refresh(startDate: newStartDate)
    }

    @Function(\Action.Cases._actuallyGetNextPage)
    private func __actuallyGetNextPage() async throws {
        guard hasNextChannelPage else { return }

        let generation = requestGeneration
        let requestStartDate = startDate
        let requestEndDate = endDate
        let page = try await getChannelPage(offset: nextChannelOffset)
        let existingChannelIDs = Set(channels.compactMap(\.id))
        let newChannels = IdentifiedArray(
            page.channels.elements.filter { channel in
                channel.id.map { !existingChannelIDs.contains($0) } ?? false
            },
            uniquingIDsWith: { existing, _ in existing }
        )
        let newPrograms = try await getProgramBlocks(
            for: newChannels,
            startDate: requestStartDate,
            endDate: requestEndDate
        )

        guard !Task.isCancelled,
              generation == requestGeneration,
              startDate == requestStartDate
        else { return }

        channels = IdentifiedArray(
            channels.elements + newChannels.elements,
            uniquingIDsWith: { existing, _ in existing }
        )
        programs.merge(newPrograms) { _, new in new }
        programsRevision &+= 1
        nextChannelOffset = page.nextOffset
        hasNextChannelPage = page.hasNextPage
    }

    @Function(\Action.Cases.refresh)
    private func _refresh(_ requestedStartDate: Date?) async throws {
        requestGeneration += 1
        let generation = requestGeneration
        let requestStartDate = requestedStartDate ?? refreshedStartDate()
        let requestEndDate = endDate(startingAt: requestStartDate)
        let page = try await getChannelPage(offset: 0)
        let newPrograms = try await getProgramBlocks(
            for: page.channels,
            startDate: requestStartDate,
            endDate: requestEndDate
        )

        guard !Task.isCancelled,
              generation == requestGeneration
        else { return }

        startDate = requestStartDate
        channels = page.channels
        programs = newPrograms
        programsRevision &+= 1
        nextChannelOffset = page.nextOffset
        hasNextChannelPage = page.hasNextPage
    }

    private func getChannelPage(offset: Int) async throws -> ChannelPage {
        let items = try await channelsLibrary.retrievePage(
            environment: Empty(),
            pageState: LibraryPageState(
                pageOffset: offset,
                pageSize: channelPageSize,
                userSession: requireUserSession()
            )
        )
        let validChannels = items.filter { channel in
            guard let id = channel.id else { return false }
            return id.nilIfBlank == id
        }

        return ChannelPage(
            channels: IdentifiedArray(
                validChannels,
                uniquingIDsWith: { existing, _ in existing }
            ),
            nextOffset: offset + items.count,
            hasNextPage: items.count >= channelPageSize
        )
    }

    private func getProgramBlocks(
        for channels: IdentifiedArrayOf<BaseItemDto>,
        startDate: Date,
        endDate: Date
    ) async throws -> [String: [ProgramBlock]] {
        let channelIDs = channels.compactMap(\.id)
        guard channelIDs.isNotEmpty else { return [:] }

        let fetchedPrograms = try await getPrograms(
            channelIDs: channelIDs,
            startDate: startDate,
            endDate: endDate
        )
        let programsByChannel = fetchedPrograms.reduce(into: [String: [BaseItemDto]]()) { result, program in
            guard let channelID = program.channelID,
                  channelID.nilIfBlank == channelID
            else { return }

            result[channelID, default: []].append(program)
        }

        return programsByChannel.mapValues { channelPrograms in
            channelPrograms.programBlocks(
                startDate: startDate,
                endDate: endDate
            )
        }
    }

    private func getPrograms(
        channelIDs: [String],
        startDate: Date,
        endDate: Date
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channelIDs
        parameters.enableImages = false
        parameters.enableTotalRecordCount = false
        parameters.enableUserData = false
        parameters.maxStartDate = endDate
        parameters.minEndDate = startDate
        parameters.sortBy = [.startDate]
        parameters.userID = try authenticatedUser.id

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await send(request)

        return response.value.items ?? []
    }

    private func endDate(startingAt startDate: Date) -> Date {
        let spanEnd = startDate.addingTimeInterval(minimumDuration.seconds)

        guard let nextDay = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: startDate)
        ) else {
            return spanEnd
        }

        return max(spanEnd, nextDay)
    }

    private func refreshedStartDate() -> Date {
        let calendar = Calendar.current

        if calendar.isDateInToday(startDate) ||
            startDate < calendar.startOfDay(for: .now)
        {
            return defaultStartDate()
        }

        return startDate
    }

    private func defaultStartDate() -> Date {
        let current = Date.now
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .second, .nanosecond], from: current)
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        let nanosecond = components.nanosecond ?? 0
        let elapsed = TimeInterval((minute % 30) * 60 + second) + TimeInterval(nanosecond) / 1_000_000_000

        return current.addingTimeInterval(-elapsed)
    }
}
