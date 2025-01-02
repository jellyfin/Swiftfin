//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OnSizeChangedModifier<Wrapped: View>: ViewModifier {

    @State
    private var size: CGSize = .zero

    @ViewBuilder
    var wrapped: (CGSize) -> Wrapped

    func body(content: Content) -> some View {
        wrapped(size)
            .trackingSize($size)
    }
}

struct EnvironmentModifier<Wrapped: View, Value>: ViewModifier {

    @Environment
    var environmentValue: Value

    @ViewBuilder
    var wrapped: (Value) -> Wrapped

    init(_ keyPath: KeyPath<EnvironmentValues, Value>, @ViewBuilder wrapped: @escaping (Value) -> Wrapped) {
        self._environmentValue = Environment(keyPath)
        self.wrapped = wrapped
    }

    func body(content: Content) -> some View {
        wrapped(environmentValue)
    }
}
