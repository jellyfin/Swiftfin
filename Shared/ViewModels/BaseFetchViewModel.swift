//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

class BaseFetchViewModel<Value: Codable>: ViewModel, Stateful {

    enum Action: Equatable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var state: State = .initial
    @Published
    var value: Value

    init(initialValue: Value) {
        self.value = initialValue
    }

    private var currentRefreshTask: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            currentRefreshTask?.cancel()

            currentRefreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let newValue = try await getValue()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.value = newValue
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    func getValue() async throws -> Value {
        fatalError("This method should be overridden in subclasses")
    }
}
