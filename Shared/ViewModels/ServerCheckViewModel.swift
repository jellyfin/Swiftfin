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

class ServerCheckViewModel: ViewModel, Stateful {

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

                    let request = Paths.getCurrentUser
                    let response = try await userSession.client.send(request)

                    await MainActor.run {
                        userSession.user.data = response.value
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
}
