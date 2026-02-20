//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

@MainActor
@Stateful
class BaseFetchViewModel<Value: Codable>: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .loop(.refreshing)
        }
    }

    enum State {
        case initial
        case refreshing
    }

    @Published
    private(set) var value: Value

    init(initialValue: Value) {
        self.value = initialValue
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        self.value = try await getValue()
    }

    func getValue() async throws -> Value {
        fatalError("This method should be overridden in subclasses")
    }
}
