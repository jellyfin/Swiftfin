//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Causes severe hangs - actually probably not the best idea
//       - object identifier equatable works okay, test more

/// A view that observes an `ObservableObject` and provides its value to a content closure.
/// Use whenever the object is derived in a context where `@ObservedObject` cannot be used directly.
struct WithObservedObject<Value: ObservableObject, Content: View>: View, Equatable {

    @ObservedObject
    private var value: Value

    private let content: (Value) -> Content

    init(
        _ value: Value,
        @ViewBuilder content: @escaping (Value) -> Content
    ) where Value: ObservableObject {
        self.value = value
        self.content = content
    }

    var body: some View {
        content(value)
    }

    static func == (lhs: WithObservedObject<Value, Content>, rhs: WithObservedObject<Value, Content>) -> Bool {
        ObjectIdentifier(lhs.value) == ObjectIdentifier(rhs.value)
    }
}
