//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ScheduledTasksViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case restartApplication
        case shutdownApplication
        case fetchTasks
        case backgroundRefresh
        case startTask(String)
        case stopTask(String)
        case error(JellyfinAPIError)
    }

    // MARK: BackgroundState

    enum BackgroundStates: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case idle
        case running
        case stopping
        case error(JellyfinAPIError)
        case fetchedTasks([TaskInfo])
    }

    private let progressPollingInterval: UInt64 = 5_000_000_000

    @Published
    final var state: State = .idle
    @Published
    var progress: [String: Double] = [:]
    @Published
    var tasks: [TaskInfo] = []

    private var sessionTasks: [String: Task<Void, Never>] = [:]

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)

        case let .startTask(taskID):
            startTaskWithProgress(taskID)

        case let .stopTask(taskID):
            stopTaskWithProgress(taskID)

        default:
            handleActionWithoutProgress(for: action)
        }
        return .running
    }

    // MARK: Handle a Non-Task Process

    private func handleActionWithoutProgress(for action: Action) {
        let task = Task {
            do {
                try await sendRequest(for: action)
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
        sessionTasks["general"] = task
    }

    // MARK: Start a Task & Record Progress

    private func startTaskWithProgress(_ taskID: String) {
        sessionTasks[taskID]?.cancel()

        let task = Task {
            do {
                try await sendRequest(for: .startTask(taskID))
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
        sessionTasks[taskID] = task
    }

    // MARK: Stop a Task & Record Progress

    private func stopTaskWithProgress(_ taskID: String) {
        sessionTasks[taskID]?.cancel()
        sessionTasks[taskID] = nil
        let task = Task {
            do {
                try await sendRequest(for: .stopTask(taskID))
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
        sessionTasks[taskID] = task
    }

    // MARK: Perform Action Request

    private func sendRequest(for action: Action) async throws {
        switch action {
        case .restartApplication:
            try await sendRestartRequest()

        case .shutdownApplication:
            try await sendShutdownRequest()

        case let .startTask(taskKey):
            try await startTask(taskKey)

        case let .stopTask(taskKey):
            try await stopTask(taskKey)

        case .fetchTasks, .backgroundRefresh:
            try await fetchTasks()

        case let .error(error):
            await MainActor.run {
                self.state = .error(error)
            }
        }
    }

    // MARK: API - Fetch Available Tasks

    private func fetchTasks() async throws {
        let request = Paths.getTasks()
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.tasks = response.value
            self.state = .fetchedTasks(self.tasks)
        }

        for task in response.value {
            if let taskID = task.id, let progressValue = task.currentProgressPercentage {
                if progressValue > 0 && progressValue < 100 {
                    trackProgress(for: taskID)
                }
            }
        }
    }

    // MARK: Track Task Progress

    private func trackProgress(for taskID: String) {
        sessionTasks[taskID]?.cancel()

        let task = Task {
            do {
                try await pollTaskProgress(for: taskID)
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
        sessionTasks[taskID] = task
    }

    // MARK: Start a New Task

    private func startTask(_ taskID: String) async throws {
        let request = Paths.startTask(taskID: taskID)
        try await userSession.client.send(request)
        try await pollTaskProgress(for: taskID)
    }

    // MARK: Stop a Task

    private func stopTask(_ taskID: String) async throws {
        let request = Paths.stopTask(taskID: taskID)
        try await userSession.client.send(request)
        try await pollTaskProgress(for: taskID)
    }

    // MARK: Restart Jellyfin

    private func sendRestartRequest() async throws {
        let request = Paths.restartApplication
        try await userSession.client.send(request)
        await MainActor.run {
            self.state = .idle
        }
    }

    // MARK: Shutdown Jellyfin

    private func sendShutdownRequest() async throws {
        let request = Paths.shutdownApplication
        try await userSession.client.send(request)
        await MainActor.run {
            self.state = .idle
        }
    }

    // MARK: Track Task Progress

    private func pollTaskProgress(for taskID: String) async throws {
        while true {
            let request = Paths.getTask(taskID: taskID)
            let response = try await userSession.client.send(request)

            let currentProgress = response.value.currentProgressPercentage

            await MainActor.run {
                self.progress[taskID] = currentProgress ?? 0
            }

            if currentProgress ?? 0 >= 100 {
                break
            }

            try await Task.sleep(nanoseconds: progressPollingInterval)
        }

        await MainActor.run {
            self.state = .idle
        }
    }
}
