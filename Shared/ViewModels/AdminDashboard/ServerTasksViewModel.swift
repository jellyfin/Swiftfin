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
    var tasks: OrderedDictionary<String, [ServerTaskObserver]> = [:]

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getTasks(isHidden: false, isEnabled: true)
        let response = try await userSession.client.send(request)

        let allTasks = response.value
        let allTaskIDs = allTasks.compactMap(\.id)

        let existingTaskIDs = tasks.values.flattened().compactMap(\.task.id)
        let removedTaskIDs = existingTaskIDs.filtering { allTaskIDs.contains($0) }

        for category in tasks.keys {
            tasks[category]?.removeAll { observer in
                guard let id = observer.task.id else { return false }
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
            if let observer = tasks.values
                .flattened()
                .first(where: { $0.task.id == id }),
                let updatedTask = allTasks.first(where: { $0.id == id })
            {
                observer.task = updatedTask
            }
        }

        for newTask in newTasks {
            let observer = ServerTaskObserver(task: newTask)
            let category = newTask.category ?? ""

            if tasks[category] != nil {
                tasks[category]?.append(observer)
            } else {
                tasks[category] = [observer]
            }
        }

        for runningTask in allTasks where runningTask.state == .running {
            if let observer = tasks.values
                .flattened()
                .first(where: { $0.task.id == runningTask.id })
            {
                await observer.start()
            }
        }

        for category in tasks.keys {
            tasks[category]?.sort { ($0.task.name ?? "") < ($1.task.name ?? "") }
        }
    }

    @Function(\Action.Cases.restartApplication)
    private func _restartApplication() async throws {
        let request = Paths.restartApplication
        try await userSession.client.send(request)
    }

    @Function(\Action.Cases.shutdownApplication)
    private func _shutdownApplication() async throws {
        let request = Paths.shutdownApplication
        try await userSession.client.send(request)
    }
}
