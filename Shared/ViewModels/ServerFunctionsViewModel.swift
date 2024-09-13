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

final class ServerFunctionsViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case scanLibrary
        case restartApplication
        case shutdownApplication
        case error(JellyfinAPIError)
    }

    // MARK: BackgroundState

    enum BackgroundStates: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case idle
        case error(JellyfinAPIError)
        case running
    }

    @Published
    final var state: State = .idle
    @Published
    var progress: Double = 100.0

    private var sessionTask: Task<Void, Never>?

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case let .error(error):
            return .error(error)
        default:
            performFunction(for: action)
            return .running
        }
    }

    // MARK: Session Management

    func performFunction(for action: Action) {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                try await sendRequest(for: action)
            } catch is CancellationError {
                print("Task was cancelled.")
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: Perform Action Request

    private func sendRequest(for action: Action) async throws {
        switch action {
        case .scanLibrary:
            try await sendLibraryScanRequest()

        case .restartApplication:
            try await sendRestartRequest()

        case .shutdownApplication:
            try await sendShutdownRequest()

        case let .error(error):
            await MainActor.run {
                self.state = .error(error)
            }
        }
    }

    // MARK: API - Scan All Libraries

    private func sendLibraryScanRequest() async throws {
        let request = Paths.refreshLibrary
        let response = try await userSession.client.send(request)

        try await pollTaskProgress(for: "RefreshLibrary")
    }

    // MARK: API - Restart Jellyfin

    private func sendRestartRequest() async throws {
        let request = Paths.restartApplication
        let response = try await userSession.client.send(request)
        self.progress = 100
        await MainActor.run {
            self.state = .idle
        }
    }

    // MARK: API - Shutdown Jellyfin

    private func sendShutdownRequest() async throws {
        let request = Paths.shutdownApplication
        let response = try await userSession.client.send(request)
        self.progress = 100
        await MainActor.run {
            self.state = .idle
        }
    }

    // MARK: API - Poll Task Progress

    private func pollTaskProgress(for taskId: String) async throws {
        let request = Paths.getTasks()
        let response = try await userSession.client.send(request)

        let filteredTasks = response.value.filter { task in
            task.key == taskId
        }

        if let taskID = filteredTasks.first?.id {
            while true {
                let request = Paths.getTask(taskID: taskID)
                let response = try await userSession.client.send(request)

                let currentProgress = response.value.currentProgressPercentage

                await MainActor.run {
                    self.progress = currentProgress ?? 0
                }

                if currentProgress ?? 0 >= 100 {
                    break
                }

                try await Task.sleep(nanoseconds: 1_000_000_000)
            }

            await MainActor.run {
                self.state = .idle
            }
        } else {
            self.progress = 100
        }
    }
}
