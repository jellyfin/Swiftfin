//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

final class ServerCheckViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case checkServer
    }

    enum State: Hashable {
        case connecting
        case connected
        case error(JellyfinAPIError)
        case serverUnreachable
        case initial
    }

    @Published
    var state: State = .initial

    private var connectCancellable: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .checkServer:
            connectCancellable?.cancel()

            connectCancellable = Task {
                do {
                    try await userSession.server.updateServerInfo()

                    let request = Paths.getCurrentUser
                    let response = try await userSession.client.send(request)

                    await MainActor.run {
                        userSession.user.data = response.value
                        self.state = .connected
                        Container.shared.currentUserSession.reset()
                    }
                } catch {
                    await MainActor.run {
                        // Check if this is a server connection failure
                        if self.isServerConnectionFailure(error) {
                            self.state = .serverUnreachable
                            // Post notification to trigger navigation to downloads
                            Notifications[.didDetectServerUnreachable].post()
                        } else {
                            self.state = .error(.init(error.localizedDescription))
                        }
                    }
                }
            }
            .asAnyCancellable()

            return .connecting
        }
    }

    private func isServerConnectionFailure(_ error: Error) -> Bool {
        // Check if the error indicates a server connection failure
        // rather than a general network issue
        let errorMessage = error.localizedDescription.lowercased()

        // Check for specific error patterns that indicate server connection issues
        let serverConnectionFailurePatterns = [
            "request timed out",
            "could not connect to the server",
            "connection was refused",
            "connection failed",
            "cannot connect to host",
            "unable to find host",
            "host unreachable",
            "network timeout",
            "operation timed out",
        ]

        // Check if error matches any server connection failure pattern
        for pattern in serverConnectionFailurePatterns {
            if errorMessage.contains(pattern) {
                return true
            }
        }

        // Check NSURLError codes for server connection issues
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet:
                return true
            default:
                break
            }
        }

        return false
    }
}
