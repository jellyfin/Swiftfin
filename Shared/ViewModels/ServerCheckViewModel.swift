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
import UIKit

final class ServerCheckViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case checkServer
    }

    enum State: Hashable {
        case connecting
        case connected
        case error(JellyfinAPIError)
        case initial
    }

    @Published
    var state: State = .initial

    private var connectCancellable: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .checkServer:
            connectCancellable?.cancel()

            // TODO: also server stuff
            connectCancellable = Task {
                do {
                    try await userSession.server.updateServerInfo()

                    try await checkServerVersion()

                    let currentUser = try await self.getCurrentUser()

                    await MainActor.run {
                        userSession.user.data = currentUser
                        self.state = .connected
                        Container.shared.currentUserSession.reset()
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .connecting
        }
    }

    // MARK: - Get Current User Data

    private func getCurrentUser() async throws -> UserDto {
        let request = Paths.getCurrentUser
        let response = try await userSession.client.send(request)

        return response.value
    }

    // MARK: - Get Current Server Info

    private func checkServerVersion() async throws {
        let request = Paths.getSystemInfo
        let response = try await userSession.client.send(request)

        guard let serverVersion = response.value.version, let apiVersion = await UIApplication.apiVersion else {
            throw JellyfinAPIError("Server version cannot be confirmed.")
        }

        if !isVersionCompatible(
            serverVersion: serverVersion,
            minimumVersion: apiVersion
        ) {
            throw JellyfinAPIError("Server version \(serverVersion) is not compatible. Minimum required version: \(apiVersion)")
        }
    }

    // MARK: - Dissect and Compare Version Strings

    private func isVersionCompatible(serverVersion: String, minimumVersion: String) -> Bool {
        let serverComponents = serverVersion.split(separator: ".").compactMap { Int($0) }
        let minComponents = minimumVersion.split(separator: ".").compactMap { Int($0) }

        guard !serverComponents.isEmpty, !minComponents.isEmpty else {
            return false
        }

        for i in 0 ..< min(serverComponents.count, minComponents.count) {
            if i >= serverComponents.count {
                return false
            }
            if i >= minComponents.count {
                return true
            }

            if serverComponents[i] > minComponents[i] {
                return true
            } else if serverComponents[i] < minComponents[i] {
                return false
            }
        }

        return serverComponents.count >= minComponents.count
    }
}
