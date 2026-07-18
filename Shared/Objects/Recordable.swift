//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

protocol Recordable: ViewModel {

    var recordableItem: BaseItemDto { get }

    func setRecordingTimerID(_ timerID: String?)
}

extension Recordable {

    var recordableProgram: BaseItemDto? {
        switch recordableItem.type {
        case .program, .liveTvProgram, .tvProgram:
            recordableItem
        case .channel, .liveTvChannel, .tvChannel:
            recordableItem.currentProgram
        default:
            nil
        }
    }

    var isRecording: Bool {
        recordableProgram?.timerID != nil
    }

    func toggleRecording() async {
        guard let program = recordableProgram, let programID = program.id else { return }

        do {
            if let timerID = program.timerID {
                try await send(Paths.cancelTimer(timerID: timerID))
                setRecordingTimerID(nil)
            } else {
                let defaults = try await send(Paths.getDefaultTimer(programID: programID)).value
                try await send(Paths.createTimer(makeTimer(from: defaults)))

                let updatedProgram = try await program.getFullItem(userSession: requireUserSession())
                setRecordingTimerID(updatedProgram.timerID)
            }
        } catch {
            logger.error("Failed to toggle recording: \(error.localizedDescription)")
        }
    }

    private func makeTimer(from defaults: SeriesTimerInfoDto) -> TimerInfoDto {
        TimerInfoDto(
            channelID: defaults.channelID,
            endDate: defaults.endDate,
            isPostPaddingRequired: defaults.isPostPaddingRequired,
            isPrePaddingRequired: defaults.isPrePaddingRequired,
            keepUntil: defaults.keepUntil,
            postPaddingSeconds: defaults.postPaddingSeconds,
            prePaddingSeconds: defaults.prePaddingSeconds,
            priority: defaults.priority,
            programID: defaults.programID,
            serviceName: defaults.serviceName,
            startDate: defaults.startDate
        )
    }
}
