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
final class RecordingTimerViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh
        case toggleRecording
        case toggleSeriesRecording
        case updateRecordingTimer(TimerInfoDto)
        case updateSeriesRecordingTimer(SeriesTimerInfoDto)

        var transition: Transition {
            switch self {
            case .refresh:
                .background(.refreshing)
            case .toggleRecording, .toggleSeriesRecording, .updateRecordingTimer, .updateSeriesRecordingTimer:
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
        case error
        case initial
    }

    @Published
    private(set) var program: BaseItemDto?
    @Published
    private(set) var recordingTimer: TimerInfoDto?
    @Published
    private(set) var seriesRecordingTimer: SeriesTimerInfoDto?

    private let item: BaseItemDto

    var canManageRecordings: Bool {
        (program?.canBeRecorded == true || recordingTimer != nil || seriesRecordingTimer != nil) &&
            !background.is(.refreshing) && !background.is(.updating)
    }

    init(item: BaseItemDto) {
        self.item = item
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        guard !background.is(.updating) else { return }
        try await refreshRecordingTimers()
    }

    @Function(\Action.Cases.toggleRecording)
    private func _toggleRecording() async throws {
        // Resolve the current program before changing a channel's recording
        try await refreshRecordingTimers()
        guard let program else { return }

        if let recordingTimerID = recordingTimer?.id {
            let request = Paths.cancelTimer(timerID: recordingTimerID)
            try await send(request)
        } else {
            guard program.canBeRecorded else { return }
            try await createRecordingTimer(for: program)
        }

        Notifications[.recordingTimersDidChange].post()
        try await refreshRecordingTimers()
    }

    @Function(\Action.Cases.toggleSeriesRecording)
    private func _toggleSeriesRecording() async throws {
        try await refreshRecordingTimers()
        guard let program, program.isSeries == true else { return }

        if let seriesRecordingTimerID = seriesRecordingTimer?.id {
            let request = Paths.cancelSeriesTimer(timerID: seriesRecordingTimerID)
            try await send(request)
        } else {
            guard program.canBeRecorded else { return }
            try await createSeriesRecordingTimer(for: program)
        }

        Notifications[.recordingTimersDidChange].post()
        try await refreshRecordingTimers()
    }

    @Function(\Action.Cases.updateRecordingTimer)
    private func _updateRecordingTimer(_ updatedRecordingTimer: TimerInfoDto) async throws {
        guard let recordingTimerID = updatedRecordingTimer.id else { return }

        let request = Paths.updateTimer(timerID: recordingTimerID, updatedRecordingTimer)
        try await send(request)

        Notifications[.recordingTimersDidChange].post()
        events.send(.updated)
        try await refreshRecordingTimers()
    }

    @Function(\Action.Cases.updateSeriesRecordingTimer)
    private func _updateSeriesRecordingTimer(_ updatedSeriesRecordingTimer: SeriesTimerInfoDto) async throws {
        guard let seriesRecordingTimerID = updatedSeriesRecordingTimer.id else { return }

        let request = Paths.updateSeriesTimer(timerID: seriesRecordingTimerID, updatedSeriesRecordingTimer)
        try await send(request)

        Notifications[.recordingTimersDidChange].post()
        events.send(.updated)
        try await refreshRecordingTimers()
    }

    private func refreshRecordingTimers() async throws {
        let program = try await resolveProgram()
        let recordingTimer = try await currentRecordingTimer(for: program)
        let seriesRecordingTimer = try await currentSeriesRecordingTimer(for: program)

        try Task.checkCancellation()

        self.program = program
        self.recordingTimer = recordingTimer
        self.seriesRecordingTimer = seriesRecordingTimer
    }

    private func resolveProgram() async throws -> BaseItemDto? {
        guard let itemID = item.id else { return nil }
        let userSession = try requireUserSession()

        switch item.type {
        case .channel, .liveTvChannel, .tvChannel:
            var parameters = Paths.GetLiveTvProgramsParameters()
            parameters.channelIDs = [itemID]
            parameters.isAiring = true
            parameters.limit = 1
            parameters.userID = userSession.user.id

            let request = Paths.getLiveTvPrograms(parameters: parameters)
            let response = try await send(request)
            return response.value.items?.first
        case .program, .liveTvProgram, .tvProgram:
            let request = Paths.getProgram(
                programID: itemID,
                userID: userSession.user.id
            )
            return try await send(request).value
        default:
            return nil
        }
    }

    private func currentRecordingTimer(for program: BaseItemDto?) async throws -> TimerInfoDto? {
        guard let recordingTimerID = program?.timerID else { return nil }

        let request = Paths.getTimer(timerID: recordingTimerID)
        let recordingTimer = try await send(request).value
        return recordingTimer.isScheduledRecording ? recordingTimer : nil
    }

    private func currentSeriesRecordingTimer(for program: BaseItemDto?) async throws -> SeriesTimerInfoDto? {
        guard let program else { return nil }

        if let seriesRecordingTimerID = program.seriesTimerID {
            let request = Paths.getSeriesTimer(timerID: seriesRecordingTimerID)
            return try await send(request).value
        }

        guard program.isSeries == true, let programID = program.id else { return nil }

        let request = Paths.getSeriesTimers()
        let response = try await send(request)
        return response.value.items?.first { $0.programID == programID }
    }

    private func createRecordingTimer(for program: BaseItemDto) async throws {
        guard let programID = program.id else { return }

        let defaultsRequest = Paths.getDefaultTimer(programID: programID)
        let defaults = try await send(defaultsRequest).value

        let recordingTimer = TimerInfoDto(
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

        let request = Paths.createTimer(recordingTimer)
        try await send(request)
    }

    private func createSeriesRecordingTimer(for program: BaseItemDto) async throws {
        guard let programID = program.id else { return }

        let defaultsRequest = Paths.getDefaultTimer(programID: programID)
        let defaults = try await send(defaultsRequest).value
        let request = Paths.createSeriesTimer(defaults)
        try await send(request)
    }
}
