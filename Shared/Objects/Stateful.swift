//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: documentation

protocol Stateful: AnyObject {

    associatedtype Action
    associatedtype State: Equatable

    var state: State { get set }

    /// Send an action to the `Stateful` object, which will
    /// `respond` to the action and set the new state.
    @MainActor
    func send(_ action: Action)

    /// Respond to a sent action and return the new state
    @MainActor
    func respond(to action: Action) -> State
}

extension Stateful {

    @MainActor
    func send(_ action: Action) {
        state = respond(to: action)
    }
}
