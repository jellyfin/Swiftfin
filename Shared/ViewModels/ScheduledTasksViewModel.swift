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

// TODO: replace current progress tracking after socket implementation

final class ScheduledTasksViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case restartApplication
        case shutdownApplication
        case fetchTasks
        case startTask(String)
        case stopTask(String)
        case error(JellyfinAPIError)
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case fetchingTasks
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var progress: [String: Double] = [:]
    @Published
    final var state: State = .initial
    @Published
    final var tasks: OrderedDictionary<String, [TaskInfo]> = [:]

    private var sessionTasks: [String: AnyCancellable] = [:]

    // MARK: - Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case let .startTask(taskID):
            handleTaskAction(action, taskID: taskID, shouldTrackProgress: true)
        case let .stopTask(taskID):
            handleTaskAction(action, taskID: taskID, shouldTrackProgress: true)
        case let .error(error):
            return .error(error)
        default:
            handleTaskAction(action)
        }
        return .content
    }

    // MARK: - Handle Task Actions

    private func handleTaskAction(_ action: Action, taskID: String? = nil, shouldTrackProgress: Bool = false) {

        sessionTasks[taskID ?? "general"]?.cancel()

        let task = Task {
            do {
                try await sendRequest(for: action)

                if let taskID = taskID, shouldTrackProgress {
                    try await pollTaskProgress(for: taskID)
                }
            } catch {
                // TODO: don't have view model error for task errors
                await MainActor.run {
                    state = .error(.init(error.localizedDescription))
                }
            }
        }
        .asAnyCancellable()

        if let taskID = taskID {
            sessionTasks[taskID] = task
        } else {
            sessionTasks["general"] = task
        }
    }

    // MARK: - Send Request via Desired API

    private func sendRequest(for action: Action) async throws {
        switch action {
        case .restartApplication:
            try await sendRestartRequest()
        case .shutdownApplication:
            try await sendShutdownRequest()
        case let .startTask(taskID):
            try await startTask(taskID)
        case let .stopTask(taskID):
            try await stopTask(taskID)
        case .fetchTasks:
            try await fetchTasks()
        case let .error(error):
            await MainActor.run {
                state = .error(error)
            }
        }
    }

    // MARK: - Fetch All Tasks

    private func fetchTasks() async throws {
        let request = Paths.getTasks(isHidden: false, isEnabled: true)
        let response = try await userSession.client.send(request)

        let newTasks = OrderedDictionary(grouping: response.value, by: { $0.category ?? "" })
            .mapValues { $0.compacted(using: \.id) }

        await MainActor.run {
            tasks = newTasks
            state = .content
        }

        for task in response.value where task.currentProgressPercentage ?? 0 > 0 && task.currentProgressPercentage ?? 0 < 100 {
            handleTaskAction(.startTask(task.id ?? ""), taskID: task.id, shouldTrackProgress: true)
        }
    }

    // MARK: - Track Task Progress

    private func pollTaskProgress(for taskID: String) async throws {
        while true {
            let request = Paths.getTask(taskID: taskID)
            let response = try await userSession.client.send(request)

            let currentProgress = response.value.currentProgressPercentage ?? 0

            await MainActor.run {
                progress[taskID] = currentProgress
            }

            if currentProgress >= 100 {
                break
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    // MARK: - Start Task From ID

    private func startTask(_ taskID: String) async throws {
        let request = Paths.startTask(taskID: taskID)
        try await userSession.client.send(request)
    }

    // MARK: - Stop Task From ID

    private func stopTask(_ taskID: String) async throws {
        let request = Paths.stopTask(taskID: taskID)
        try await userSession.client.send(request)
    }

    // MARK: - Restart Application

    private func sendRestartRequest() async throws {
        let request = Paths.restartApplication
        try await userSession.client.send(request)
    }

    // MARK: - Shutdown Application

    private func sendShutdownRequest() async throws {
        let request = Paths.shutdownApplication
        try await userSession.client.send(request)
    }
}
