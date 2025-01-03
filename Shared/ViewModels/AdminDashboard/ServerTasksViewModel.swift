//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: do something for errors from restart/shutdown
//       - toast?

final class ServerTasksViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case restartApplication
        case shutdownApplication
        case getTasks
        case refreshTasks
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingTasks
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

    private var getTasksCancellable: AnyCancellable?

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
        case .getTasks:
            getTasksCancellable?.cancel()

            getTasksCancellable = Task {
                do {
                    try await getTasks()

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return state
        case .refreshTasks:
            tasks.removeAll()
            getTasksCancellable?.cancel()

            getTasksCancellable = Task {
                do {
                    await MainActor.run {
                        self.state = .initial
                    }

                    try await getTasks()

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        }
    }

    // MARK: - Get All Tasks

    // TODO: update tasks like `ActiveSessionsViewModel`
    private func getTasks() async throws {
        let request = Paths.getTasks(isHidden: false, isEnabled: true)
        let response = try await userSession.client.send(request)

        if tasks.isEmpty {
            let observers = response.value
                .sorted(using: \.category)
                .map { ServerTaskObserver(task: $0) }

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
