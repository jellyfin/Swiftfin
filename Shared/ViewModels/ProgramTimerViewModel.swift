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
@Stateful
final class ProgramTimerViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case toggleRecording
        case toggleSeriesRecording
        case updateTimer(TimerInfoDto)
        case updateSeriesTimer(SeriesTimerInfoDto)

        var transition: Transition {
            switch self {
            case .refresh:
                .background(.refreshing)
            case .toggleRecording, .toggleSeriesRecording, .updateTimer, .updateSeriesTimer:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case refreshing
        case updating
    }

    enum Event {
        case updated
    }

    enum State {
        case initial
        case error
    }

    @Published
    private(set) var program: BaseItemDto
    @Published
    private(set) var seriesTimer: SeriesTimerInfoDto?
    @Published
    private(set) var timer: TimerInfoDto?

    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
        self.program = item
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        await performRefresh()
    }

    @Function(\Action.Cases.toggleRecording)
    private func _toggleRecording() async throws {
        let beforeTimer = timer

        if let timerID = beforeTimer?.id {
            timer = nil
            do {
                try await send(Paths.cancelTimer(timerID: timerID))
            } catch {
                timer = beforeTimer
                throw error
            }
        } else {
            timer = TimerInfoDto(programID: program.id)
            do {
                try await createTimer()
            } catch {
                timer = nil
                throw error
            }
        }

        await performRefresh()
        notifyTimersChanged()
    }

    @Function(\Action.Cases.toggleSeriesRecording)
    private func _toggleSeriesRecording() async throws {
        let beforeSeriesTimer = seriesTimer

        if let timerID = beforeSeriesTimer?.id {
            seriesTimer = nil
            do {
                try await send(Paths.cancelSeriesTimer(timerID: timerID))
            } catch {
                seriesTimer = beforeSeriesTimer
                throw error
            }
        } else {
            seriesTimer = SeriesTimerInfoDto(programID: program.id)
            do {
                try await createSeriesTimer()
            } catch {
                seriesTimer = nil
                throw error
            }
        }

        await performRefresh()
        notifyTimersChanged()
    }

    @Function(\Action.Cases.updateTimer)
    private func _updateTimer(_ updatedTimer: TimerInfoDto) async throws {
        guard let timerID = updatedTimer.id else { return }

        try await send(Paths.updateTimer(timerID: timerID, updatedTimer))
        await performRefresh()
        notifyTimersChanged()
        events.send(.updated)
    }

    @Function(\Action.Cases.updateSeriesTimer)
    private func _updateSeriesTimer(_ updatedTimer: SeriesTimerInfoDto) async throws {
        guard let timerID = updatedTimer.id else { return }

        try await send(Paths.updateSeriesTimer(timerID: timerID, updatedTimer))
        await performRefresh()
        notifyTimersChanged()
        events.send(.updated)
    }

    private func performRefresh() async {
        guard let fullProgram = try? await resolveProgram() else { return }

        program = fullProgram
        timer = try? await currentTimer()
        seriesTimer = try? await currentSeriesTimer()
    }

    private func resolveProgram() async throws -> BaseItemDto? {
        switch item.type {
        case .channel, .liveTvChannel, .tvChannel:
            var parameters = Paths.GetLiveTvProgramsParameters()
            parameters.channelIDs = item.id.map { [$0] }
            parameters.isAiring = true
            parameters.limit = 1
            parameters.userID = userSession?.user.id

            let request = Paths.getLiveTvPrograms(parameters: parameters)

            return try await send(request).value.items?.first
        default:
            guard let programID = item.id else { return nil }

            let request = Paths.getProgram(
                programID: programID,
                userID: userSession?.user.id
            )

            return try await send(request).value
        }
    }

    private func currentTimer() async throws -> TimerInfoDto? {
        guard let timerID = program.timerID else { return nil }

        let timer = try await send(Paths.getTimer(timerID: timerID)).value

        if let endDate = timer.endDate, endDate <= Date() {
            return nil
        }

        switch timer.status {
        case .cancelled, .completed, .error:
            return nil
        default:
            return timer
        }
    }

    private func currentSeriesTimer() async throws -> SeriesTimerInfoDto? {
        if let seriesTimerID = program.seriesTimerID {
            return try await send(Paths.getSeriesTimer(timerID: seriesTimerID)).value
        }

        guard program.isSeries == true else { return nil }

        let response = try await send(Paths.getSeriesTimers())

        return response.value.items?.first { $0.programID == program.id }
    }

    private func createTimer() async throws {
        guard let programID = program.id else { return }

        let defaults = try await send(Paths.getDefaultTimer(programID: programID)).value

        let newTimer = TimerInfoDto(
            channelID: defaults.channelID ?? program.channelID,
            endDate: defaults.endDate ?? program.endDate,
            externalChannelID: defaults.externalChannelID,
            externalProgramID: defaults.externalProgramID,
            isPostPaddingRequired: defaults.isPostPaddingRequired,
            isPrePaddingRequired: defaults.isPrePaddingRequired,
            keepUntil: defaults.keepUntil,
            name: defaults.name ?? program.name,
            overview: defaults.overview,
            postPaddingSeconds: defaults.postPaddingSeconds,
            prePaddingSeconds: defaults.prePaddingSeconds,
            priority: defaults.priority,
            programID: defaults.programID ?? programID,
            serverID: defaults.serverID,
            serviceName: defaults.serviceName,
            startDate: defaults.startDate ?? program.startDate
        )

        try await send(Paths.createTimer(newTimer))
    }

    private func createSeriesTimer() async throws {
        guard let programID = program.id else { return }

        let defaults = try await send(Paths.getDefaultTimer(programID: programID)).value

        try await send(Paths.createSeriesTimer(defaults))
    }

    private func notifyTimersChanged() {
        Notifications[.timersDidChange].post()
    }
}
