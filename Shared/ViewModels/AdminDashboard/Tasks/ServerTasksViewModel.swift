//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: do something for errors from restart/shutdown
//       - toast?

@MainActor
@Stateful
final class ServerTasksViewModel: ViewModel {

    @CasePathable
    enum Action {
        case restartApplication
        case shutdownApplication
        case refresh

        var transition: Transition {
            switch self {
            case .restartApplication, .shutdownApplication:
                .none
            case .refresh:
                .to(.initial, then: .content)
                    .whenBackground(.refreshing)
            }
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case content
        case error
        case initial
    }

    @Published
    var tasks: OrderedDictionary<String, [ServerTaskViewModel]> = [:]

    override init() {
        super.init()

        Container.shared.userSessionManager()
            .$currentSession
            .compactMap { $0?.serverSocketManager.scheduledTasks(interval: .seconds(2)) }
            .switchToLatest()
            .sink { [weak self] tasks in
                Task { @MainActor in
                    self?.updateTasks(tasks)
                }
            }
            .store(in: &cancellables)
    }

    private func updateTasks(_ updatedTasks: [TaskInfo]) {
        for taskViewModel in tasks.values.flattened() {
            guard let updatedTask = updatedTasks.first(where: { $0.id == taskViewModel.task.id }) else {
                continue
            }

            taskViewModel.task = updatedTask
        }
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getTasks(isHidden: false, isEnabled: true)
        let response = try await send(request)

        let allTasks = response.value
        let allTaskIDs = allTasks.compactMap(\.id)

        let existingTaskIDs = tasks.values.flattened().compactMap(\.task.id)
        let removedTaskIDs = existingTaskIDs.filtering { allTaskIDs.contains($0) }

        for category in tasks.keys {
            tasks[category]?.removeAll { taskViewModel in
                guard let id = taskViewModel.task.id else { return false }
                return removedTaskIDs.contains(id)
            }
            if tasks[category]?.isEmpty == true {
                tasks[category] = nil
            }
        }

        let existingIDs = existingTaskIDs.filter { allTaskIDs.contains($0) }
        let newTasks = allTasks.filter { task in
            guard let id = task.id else { return false }
            return !existingTaskIDs.contains(id)
        }

        for id in existingIDs {
            if let taskViewModel = tasks.values
                .flattened()
                .first(where: { $0.task.id == id }),
                let updatedTask = allTasks.first(where: { $0.id == id })
            {
                taskViewModel.task = updatedTask
            }
        }

        for newTask in newTasks {
            let taskViewModel = ServerTaskViewModel(task: newTask)
            let category = newTask.category ?? ""

            if tasks[category] != nil {
                tasks[category]?.append(taskViewModel)
            } else {
                tasks[category] = [taskViewModel]
            }
        }

        for category in tasks.keys {
            tasks[category]?.sort { ($0.task.name ?? "") < ($1.task.name ?? "") }
        }

        tasks.sort()
    }

    @Function(\Action.Cases.restartApplication)
    private func _restartApplication() async throws {
        let request = Paths.restartApplication
        try await send(request)
    }

    @Function(\Action.Cases.shutdownApplication)
    private func _shutdownApplication() async throws {
        let request = Paths.shutdownApplication
        try await send(request)
    }
}
