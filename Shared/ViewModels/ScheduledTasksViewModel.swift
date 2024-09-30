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

// TODO: do something for errors from restart/shutdown
//       - toast?

final class ScheduledTasksViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case restartApplication
        case shutdownApplication
        case fetchTasks
        case refreshTasks
        case stopObserving
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
    final var state: State = .initial
    @Published
    final var tasks: OrderedDictionary<String, [ServerTaskObserver]> = [:]

    private var fetchTasksCancellable: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .restartApplication:
            Task {
                try await sendRestartRequest()
            }
            .store(in: &cancellables)

            return .content
        case .shutdownApplication:
            Task {
                try await sendShutdownRequest()
            }
            .store(in: &cancellables)

            return .content
        case .fetchTasks:
            fetchTasksCancellable?.cancel()

            fetchTasksCancellable = Task {
                do {
                    try await fetchTasks()

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.send(.stopObserving)
                    }
                }
            }
            .asAnyCancellable()

            return state
        case .refreshTasks:
            fetchTasksCancellable?.cancel()

            fetchTasksCancellable = Task {
                do {
                    try await fetchTasks()

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.send(.stopObserving)
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        case .stopObserving:
            for observer in tasks.values.flatMap(\.self) where observer.state == .running {
                // crash if not wrapped on view pop
                DispatchQueue.main.async {
                    observer.send(.stopObserving)
                }
            }

            return .initial
        }
    }

    // MARK: - Fetch All Tasks

    // Note: If task list was modified while on this view it won't update
    //       until popped and presented again. However, that is a rare case.
    private func fetchTasks() async throws {
        let request = Paths.getTasks(isHidden: false, isEnabled: true)
        let response = try await userSession.client.send(request)

        if tasks.isEmpty {
            let observers = response.value.map { ServerTaskObserver(task: $0) }
            let newTasks = OrderedDictionary(grouping: observers, by: { $0.task.category ?? "" })

            await MainActor.run {
                self.tasks = newTasks
            }
        }

        for runningTask in response.value where runningTask.state == .running {
            if let observer = tasks.values
                .flatMap(\.self)
                .first(where: { $0.task.id == runningTask.id })
            {
                await observer.send(.start)
            }
        }
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
