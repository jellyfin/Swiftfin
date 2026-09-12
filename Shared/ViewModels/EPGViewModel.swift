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
        let channels: [ItemPatch]
        let pageState: LibraryPageState
        let nextOffset: Int
        let hasNextPage: Bool
    }

    @Published
    private(set) var channels: ItemCollection = IdentifiedArray(
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

        userSession?.items.changes
            .sink { [weak self] change in
                guard let self else { return }
                switch change {
                case let .deleted(id):
                    self.channels.removeAll { $0.itemID == id }
                    self.programs.removeValue(forKey: id)
                    for channelID in self.programs.keys {
                        self.programs[channelID]?.removeAll { $0.programs.isEmpty }
                    }
                    self.programsRevision &+= 1
                case .invalidated:
                    self.requestGeneration += 1
                    self.channels.removeAll()
                    self.programs.removeAll()
                    self.hasNextChannelPage = false
                    self.programsRevision &+= 1
                case .updated:
                    break
                }
            }
            .store(in: &cancellables)

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
        try await loadChannels(replacing: false, from: startDate)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh(_ requestedStartDate: Date?) async throws {
        requestGeneration += 1
        try await loadChannels(replacing: true, from: requestedStartDate ?? refreshedStartDate())
    }

    private func loadChannels(replacing: Bool, from date: Date) async throws {
        let generation = requestGeneration
        let offset = replacing ? 0 : nextChannelOffset
        let end = endDate(startingAt: date)
        let page = try await getChannelPage(offset: offset)
        let existingIDs = replacing ? Set<String>() : Set(channels.map(\.itemID))
        let patches = page.channels.filter { !existingIDs.contains($0.value.id ?? "") }
        let programPatches = try await getPrograms(
            channelIDs: patches.compactMap(\.value.id),
            startDate: date,
            endDate: end,
            userSession: page.pageState.userSession
        )

        guard !Task.isCancelled, generation == requestGeneration,
              replacing || offset == nextChannelOffset else { return }
        try page.pageState.userSession.items.validate(page.pageState.itemRequest)
        let newChannels = try channelsLibrary.materialize(patches, pageState: page.pageState)
        let newPrograms = try makeProgramBlocks(programPatches, pageState: page.pageState, startDate: date, endDate: end)
        if replacing {
            channels = IdentifiedArray(newChannels, uniquingIDsWith: { existing, _ in existing })
            programs = newPrograms
            startDate = date
        } else {
            for channel in newChannels {
                channels.updateOrAppend(channel)
            }
            programs.merge(newPrograms) { _, new in new }
        }
        programsRevision &+= 1
        nextChannelOffset = page.nextOffset
        hasNextChannelPage = page.hasNextPage
    }

    private func getChannelPage(offset: Int) async throws -> ChannelPage {
        let pageState = try LibraryPageState(pageOffset: offset, pageSize: channelPageSize, userSession: requireUserSession())
        let patches = try await channelsLibrary.retrievePage(environment: Empty(), pageState: pageState)
        let progress = pageState.progress(returnedCount: patches.count)
        return ChannelPage(
            channels: patches.filter { $0.value.id?.nilIfBlank != nil },
            pageState: pageState,
            nextOffset: progress.nextOffset,
            hasNextPage: progress.hasNextPage
        )
    }

    private func makeProgramBlocks(
        _ patches: [ItemPatch],
        pageState: LibraryPageState,
        startDate: Date,
        endDate: Date
    ) throws -> [String: [ProgramBlock]] {
        let entries = try patches.compactMap { patch -> ItemEntry? in
            guard patch.value.id?.nilIfBlank != nil,
                  let record = try pageState.userSession.items.merge(patch, token: pageState.itemRequest) else { return nil }
            return ItemEntry(item: record)
        }
        let byChannel = Dictionary(grouping: entries) { $0.channelID ?? "" }
        return byChannel.mapValues { entries in
            entries.map(\.snapshot).programBlocks(startDate: startDate, endDate: endDate)
        }
    }

    private func getPrograms(
        channelIDs: [String],
        startDate: Date,
        endDate: Date,
        userSession: UserSession
    ) async throws -> [ItemPatch] {
        guard !channelIDs.isEmpty else { return [] }
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channelIDs
        parameters.enableImages = false
        parameters.enableTotalRecordCount = false
        parameters.enableUserData = false
        parameters.maxStartDate = endDate
        parameters.minEndDate = startDate
        parameters.sortBy = [.startDate]
        parameters.userID = userSession.user.id
        let response = try await userSession.client.send(Paths.getLiveTvPrograms(parameters: parameters))
        return try ItemPatch.items(from: response)
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
