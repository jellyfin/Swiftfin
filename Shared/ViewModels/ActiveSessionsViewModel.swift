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

class ActiveSessionsViewModel: ViewModel {
    @Published
    var sessions: [SessionInfo] = []
    @Published
    var isLoading: Bool = false
    @Published
    var error: Error?

    private var timerCancellable: AnyCancellable?

    override init() {
        super.init()
        startTimer()
    }

    /// Starts a timer that triggers `loadSessions` every 2 seconds.
    func startTimer() {
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.loadSessions()
            }
    }

    /// Stops the timer to prevent further calls to `loadSessions`.
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Loads active sessions asynchronously.
    func loadSessions(deviceID: String? = nil) {
        isLoading = true
        error = nil

        Task {
            do {
                let fetchedSessions = try await getSessions(deviceID: deviceID)
                DispatchQueue.main.async {
                    self.sessions = fetchedSessions
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }

    /// Fetches active sessions asynchronously.
    /// - Returns: An array of `SessionInfo` if the request is successful.
    /// - Throws: An error if the request fails.
    private func getSessions(deviceID: String? = nil) async throws -> [SessionInfo] {
        let request = Paths.getSessions(parameters: createParameters(deviceID: deviceID))
        let response = try await userSession.client.send(request)
        return response.value
    }

    /// Creates the request parameters for fetching sessions.
    /// - Returns: A `Paths.GetSessionsParameters` object with the appropriate settings.
    private func createParameters(deviceID: String? = nil) -> Paths.GetSessionsParameters {
        var parameters = Paths.GetSessionsParameters()
        if let deviceID = deviceID {
            parameters.deviceID = deviceID
        }
        parameters.activeWithinSeconds = 960
        return parameters
    }

    deinit {
        stopTimer()
    }
}
