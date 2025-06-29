//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

typealias TypeViewRegistry = TypeValueRegistry<(Any) -> AnyView>

extension EnvironmentValues {

    @Entry
    var posterOverlayRegistry: TypeViewRegistry = .init()
}

extension View {

    func posterOverlay<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View
    ) -> some View {
        modifier(
            EnvironmentView.Registerer(
                content: { AnyView(content($0)) },
                keyPath: \.posterOverlayRegistry
            )
        )
    }
}

@propertyWrapper
struct EnvironmentTypeValue<Value>: DynamicProperty {

    @Environment
    private var registry: TypeViewRegistry

    init(_ keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>) {
        self._registry = Environment(keyPath)
    }

    var wrappedValue: (Value) -> AnyView {
        registry.getvalue(for: Value.self) ?? { _ in AnyView(EmptyView()) }
    }
}

enum EnvironmentView<Value> {

    struct Registerer: ViewModifier {

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

//    struct Extractor: ViewModifier {
//
//        @Environment
//        private var environmentRegistry: TypeViewRegistry
//
//        private let value: Value
//        private let keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>
//
//        init(
//            value: Value,
//            keyPath: WritableKeyPath<EnvironmentValues, TypeViewRegistry>
//        ) {
//            self.value = value
//            self.keyPath = keyPath
//            self._environmentRegistry = Environment(keyPath)
//        }
//
//        func body(content: Content) -> some View {
//
//            let contextMenu = contextMenuRegistry.getvalue(for: Value.self)?(value) ?? (AnyView(EmptyView()), nil)
//
//            if let previewOverride = previewOverride {
//                content
//                    .contextMenu(
//                        menuItems: { contextMenu.0 },
//                        preview: { previewOverride(value) }
//                    )
//            } else if let preview = contextMenu.1 {
//                content
//                    .contextMenu(
//                        menuItems: { contextMenu.0 },
//                        preview: { preview }
//                    )
//            } else {
//                content
//                    .contextMenu(
//                        menuItems: { contextMenu.0 }
//                    )
//            }
//        }
//    }
}
