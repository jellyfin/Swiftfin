//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Observation

@MainActor
@Observable
final class SleepTimer: VideoPlayerOverlayActionProviding {

    let id = "SleepTimer"

    private(set) var deadline: Date?
    private(set) var snoozePromptID: UUID?

    @ObservationIgnored
    private weak var pausedSession: MediaSession?
    @ObservationIgnored
    private var task: Task<Void, Never>?
    @ObservationIgnored
    private var resumeObservation: ObservationToken?
    @ObservationIgnored
    private let currentSession: @MainActor () -> MediaSession?

    init(currentSession: @escaping @MainActor () -> MediaSession?) {
        self.currentSession = currentSession
    }

    var overlayActions: [VideoPlayerOverlayAction] {
        guard let snoozePromptID,
              let pausedSession,
              pausedSession === currentSession(),
              pausedSession.playbackRequestStatus == .paused else { return [] }

        let snooze = Duration.seconds(Defaults[.VideoPlayer.sleepTimerSnoozeInterval] * 60)

        return [VideoPlayerOverlayAction(
            id: snoozePromptID.uuidString,
            title: L10n.snoozeDuration(snooze.formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))),
            systemImage: VideoPlayerActionButton.sleepTimer.systemImage
        ) { [weak self] in
            guard let self else { return }

            start(until: .now.addingTimeInterval(snooze.seconds))
            pausedSession.setPlaybackRequestStatus(status: .playing)
        }]
    }

    func start(until date: Date) {
        clearSnoozePrompt()
        task?.cancel()
        deadline = date

        task = Task { [weak self] in
            try? await Task.sleep(
                until: ContinuousClock.now + .seconds(date.timeIntervalSinceNow),
                clock: .continuous
            )
            guard !Task.isCancelled, let self else { return }

            task = nil
            deadline = nil

            guard let session = currentSession() else { return }

            switch Defaults[.VideoPlayer.sleepTimerAction] {
            case .pause:
                session.setPlaybackRequestStatus(status: .paused)
                pausedSession = session
                snoozePromptID = UUID()
                resumeObservation = ObservationToken { [weak session] in
                    session?.playbackRequestStatus
                } onChange: { [weak self] status in
                    if status == .playing {
                        self?.clearSnoozePrompt()
                    }
                }

            case .stop:
                session.stop()
            }
        }
    }

    func cancel() {
        clearSnoozePrompt()
        task?.cancel()
        task = nil
        deadline = nil
    }

    private func clearSnoozePrompt() {
        snoozePromptID = nil
        pausedSession = nil
        resumeObservation = nil
    }
}
