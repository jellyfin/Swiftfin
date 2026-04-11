//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

typealias TypeViewRegistry = TypeValueRegistry<(Any) -> AnyView>

@propertyWrapper
struct EnvironmentTypeValue<Value>: DynamicProperty {

    @Environment
    private var registry: TypeViewRegistry

    init(_ keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>) {
        self._registry = Environment(keyPath)
    }

    var wrappedValue: ((Value) -> AnyView)? {
        registry.getvalue(for: Value.self)
    }
}

enum EnvironmentView<Value> {

    struct Registar: ViewModifier {

        @Environment
        private var environmentRegistry: TypeViewRegistry

        private let content: (Any) -> AnyView
        private let keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>

        init(
            content: @escaping (Value) -> AnyView,
            keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>
        ) {
            self.content = { value in
                guard let value = value as? Value else {
                    return AnyView(EmptyView())
                }
                return AnyView(content(value))
            }

            self.keyPath = keyPath
            self._environmentRegistry = Environment(keyPath)
        }

        func body(content: Content) -> some View {
            content
                .environment(keyPath, environmentRegistry.insertOrReplace(self.content, for: Value.self))
        }
    }
}
