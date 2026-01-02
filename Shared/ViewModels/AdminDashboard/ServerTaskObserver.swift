//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

// TODO: refactor with socket implementation
// TODO: for trigger updating, could temp set new triggers
//       and set back on failure

@MainActor
@Stateful
final class ServerTaskObserver: ViewModel, Identifiable {

    @CasePathable
    enum Action {
        case start
        case stop
        case addTrigger(TaskTriggerInfo)
        case removeTrigger(TaskTriggerInfo)

        var transition: Transition {
            switch self {
            case .start:
                .to(.running, then: .initial)
                    .whenBackground(.observing)
            case .stop:
                .to(.initial)
            case .addTrigger, .removeTrigger:
                .background(.updating)
            }
        }
    }

    enum BackgroundState {
        case updating
        case observing
    }

    enum State {
        case error
        case initial
        case running
    }

    @Published
    var task: TaskInfo

    var id: String? { task.id }

    init(task: TaskInfo) {
        self.task = task
    }

    @Function(\Action.Cases.start)
    private func _start() async throws {
        guard let id = task.id else { return }

        let request = Paths.startTask(taskID: id)
        try await userSession.client.send(request)

        try await pollTaskProgress(id: id)
    }

    @Function(\Action.Cases.stop)
    private func _stop() async throws {
        guard let id = task.id else { return }

        let request = Paths.stopTask(taskID: id)
        try await userSession.client.send(request)

        try await pollTaskProgress(id: id)
    }

    @Function(\Action.Cases.addTrigger)
    private func _addTrigger(_ trigger: TaskTriggerInfo) async throws {
        let updatedTriggers = (task.triggers ?? [])
            .appending(trigger)

        try await updateTriggers(updatedTriggers)
    }

    @Function(\Action.Cases.removeTrigger)
    private func _removeTrigger(_ trigger: TaskTriggerInfo) async throws {
        let updatedTriggers = (task.triggers ?? [])
            .filtering { $0 == trigger }

        try await updateTriggers(updatedTriggers)
    }

    private func pollTaskProgress(id: String) async throws {
        while true {
            let request = Paths.getTask(taskID: id)
            let response = try await userSession.client.send(request)

            task = response.value

            guard response.value.state == .running || response.value.state == .cancelling else {
                break
            }

            try await Task.sleep(for: .seconds(2))
        }
    }

    private func updateTriggers(_ updatedTriggers: [TaskTriggerInfo]) async throws {
        guard let id = task.id else { return }
        let updateRequest = Paths.updateTask(taskID: id, updatedTriggers)
        try await userSession.client.send(updateRequest)

        task.triggers = updatedTriggers
    }
}
