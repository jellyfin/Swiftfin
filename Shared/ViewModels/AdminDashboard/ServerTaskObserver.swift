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

// TODO: refactor with socket implementation
// TODO: for trigger updating, could temp set new triggers
//       and set back on failure

final class ServerTaskObserver: ViewModel, Stateful, Eventful, Identifiable {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
    }

    enum BackgroundState {
        case updatingTriggers
    }

    // MARK: Action

    enum Action: Equatable {
        case start
        case stop
        case stopObserving
        case addTrigger(TaskTriggerInfo)
        case removeTrigger(TaskTriggerInfo)
    }

    // MARK: State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
        case running
    }

    // MARK: Published Values

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var state: State = .initial
    @Published
    private(set) var task: TaskInfo

    // MARK: Cancellable Tasks

    private var progressCancellable: AnyCancellable?
    private var cancelCancellable: AnyCancellable?

    // MARK: Initialize from TaskId

    var id: String? { task.id }

    init(task: TaskInfo) {
        self.task = task
    }

    // MARK: Event Variables

    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .start:
            if case .running = state {
                return state
            }

            progressCancellable = Task {
                do {
                    try await start()

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .running
        case .stop:
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                do {
                    try await stop()

                    await MainActor.run {
                        self.state = .initial
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        case .stopObserving:
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            return .initial
        case let .addTrigger(trigger):
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                let updatedTriggers = (task.triggers ?? [])
                    .appending(trigger)

                await MainActor.run {
                    _ = self.backgroundStates.append(.updatingTriggers)
                }

                do {
                    try await updateTriggers(updatedTriggers)
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updatingTriggers)
                }
            }
            .asAnyCancellable()

            return .running
        case let .removeTrigger(trigger):
            progressCancellable?.cancel()
            cancelCancellable?.cancel()

            cancelCancellable = Task {
                var updatedTriggers = (task.triggers ?? [])
                updatedTriggers.removeAll { $0 == trigger }

                await MainActor.run {
                    _ = self.backgroundStates.append(.updatingTriggers)
                }

                do {
                    try await updateTriggers(updatedTriggers)
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updatingTriggers)
                }
            }
            .asAnyCancellable()

            return .running
        }
    }

    // MARK: Start Task

    private func start() async throws {
        guard let id = task.id else { return }

        let request = Paths.startTask(taskID: id)
        try await userSession.client.send(request)

        try await pollTaskProgress(id: id)
    }

    // MARK: Poll Task Progress

    private func pollTaskProgress(id: String) async throws {
        while true {
            let request = Paths.getTask(taskID: id)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                self.task = response.value
            }

            guard response.value.state == .running || response.value.state == .cancelling else {
                break
            }

            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
    }

    // MARK: Stop Task

    private func stop() async throws {
        guard let id = task.id else { return }

        let request = Paths.stopTask(taskID: id)
        try await userSession.client.send(request)

        try await pollTaskProgress(id: id)
    }

    // MARK: Update Triggers

    private func updateTriggers(_ updatedTriggers: [TaskTriggerInfo]) async throws {
        guard let id = task.id else { return }
        let updateRequest = Paths.updateTask(taskID: id, updatedTriggers)
        try await userSession.client.send(updateRequest)

        await MainActor.run {
            self.task.triggers = updatedTriggers
        }
    }
}
