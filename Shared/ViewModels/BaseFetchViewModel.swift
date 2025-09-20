//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

@MainActor
@Stateful
class BaseFetchViewModel<Value: Codable>: ViewModel {

    @CasePathable
    enum Action {
        case refresh
    }

    // MARK: State

    enum State {
        case content
        case error
        case initial
        case refreshing
    }

    @Published
    var value: Value

    init(initialValue: Value) {
        self.value = initialValue
        super.init()
        Task { await setupPublisherAssignments() }
    }

    private var currentRefreshTask: AnyCancellable?

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let newValue = try await getValue()

        await MainActor.run {
            self.value = newValue
            self.state = .content
        }
    }

    func getValue() async throws -> Value {
        fatalError("This method should be overridden in subclasses")
    }
}
