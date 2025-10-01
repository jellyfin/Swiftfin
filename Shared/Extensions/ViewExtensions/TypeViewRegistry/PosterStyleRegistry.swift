//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol WithDefaultValue {
    static var `default`: Self { get }
}

// TODO: have layout values for `PosterHStack`?
//       - or be based on size/poster display value?

// TODO: rename `PosterButtonStyle`
struct PosterStyleEnvironment: WithDefaultValue {

    var displayType: PosterDisplayType
    var indicators: Set<PosterOverlayIndicator>
    var label: AnyView
    var overlay: AnyView
    var useParentImages: Bool
    var size: PosterDisplayType.Size

    init(
        displayType: PosterDisplayType = .portrait,
        indicators: Set<PosterOverlayIndicator> = [],
        label: some View = EmptyView(),
        overlay: some View = EmptyView(),
        useParentImages: Bool = false,
        size: PosterDisplayType.Size = .medium
    ) {
        self.displayType = displayType
        self.indicators = indicators
        self.label = label.eraseToAnyView()
        self.overlay = overlay.eraseToAnyView()
        self.useParentImages = useParentImages
        self.size = size
    }

    static let `default` = PosterStyleEnvironment(
        displayType: .portrait,
        indicators: [],
        label: EmptyView(),
        overlay: EmptyView(),
        useParentImages: false,
        size: .medium
    )
}

extension EnvironmentValues {

    @Entry
    var posterStyleRegistry: TypeValueRegistry<(Any) -> PosterStyleEnvironment> = .init()
}

extension View {

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: PosterStyleEnvironment
    ) -> some View {
        modifier(
            _EnvironmentView<P, PosterStyleEnvironment>.ExistingValueRegistrar(
                content: { _, _ in style },
                keyPath: \.posterStyleRegistry
            )
        )
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (P) -> PosterStyleEnvironment
    ) -> some View {
        modifier(
            _EnvironmentView<P, PosterStyleEnvironment>.ExistingValueRegistrar(
                content: { _, p in style(p) },
                keyPath: \.posterStyleRegistry
            )
        )
    }

    @ViewBuilder
    func posterStyle<P: Poster>(
        for type: P.Type,
        style: @escaping (PosterStyleEnvironment, P) -> PosterStyleEnvironment
    ) -> some View {
        modifier(
            _EnvironmentView<P, PosterStyleEnvironment>.WithDefaultValueExistingValueRegistrar(
                content: style,
                keyPath: \.posterStyleRegistry
            )
        )
    }
}

@propertyWrapper
struct EnvironmentTypeValue<KeyType, Value>: DynamicProperty {

    @Environment
    private var registry: TypeValueRegistry<Value>

    init(
        _ keyPath: WritableKeyPath<EnvironmentValues, TypeValueRegistry<Value>>
    ) {
        self._registry = Environment(keyPath)
    }

    var wrappedValue: Value? {
        registry.getvalue(for: KeyType.self)
    }
}

enum _EnvironmentView<KeyType, Value> {

    struct ExistingValueRegistrar: ViewModifier {

        @Environment
        private var environmentRegistry: TypeValueRegistry<(Any) -> Value>

        private let content: (TypeValueRegistry<(Any) -> Value>) -> ((Any) -> Value)
        private let keyPath: WritableKeyPath<EnvironmentValues, TypeValueRegistry<(Any) -> Value>>

        init(
            content: @escaping (Value?, KeyType) -> Value,
            keyPath: WritableKeyPath<EnvironmentValues, TypeValueRegistry<(Any) -> Value>>
        ) {
            self.keyPath = keyPath
            self._environmentRegistry = Environment(keyPath)

            self.content = { registry in
                { keyType in
                    guard let keyType = keyType as? KeyType else {
                        fatalError()
                    }
                    let existingValue = registry.getvalue(for: KeyType.self)?(keyType)
                    return content(existingValue, keyType)
                }
            }
        }

        func body(content: Content) -> some View {
            content
                .environment(
                    keyPath,
                    environmentRegistry.insertOrReplace(
                        self.content(environmentRegistry),
                        for: KeyType.self
                    )
                )
        }
    }
}

extension _EnvironmentView where Value: WithDefaultValue {

    struct WithDefaultValueExistingValueRegistrar: ViewModifier {

        @Environment
        private var environmentRegistry: TypeValueRegistry<(Any) -> Value>

        private let content: (TypeValueRegistry<(Any) -> Value>) -> ((Any) -> Value)
        private let keyPath: WritableKeyPath<EnvironmentValues, TypeValueRegistry<(Any) -> Value>>

        init(
            content: @escaping (Value, KeyType) -> Value,
            keyPath: WritableKeyPath<EnvironmentValues, TypeValueRegistry<(Any) -> Value>>
        ) {
            self.keyPath = keyPath
            self._environmentRegistry = Environment(keyPath)

            self.content = { registry in
                { keyType in
                    guard let keyType = keyType as? KeyType else {
                        fatalError()
                    }
                    let existingValue = registry.getvalue(for: KeyType.self)?(keyType) ?? Value.default
                    return content(existingValue, keyType)
                }
            }
        }

        func body(content: Content) -> some View {
            content
                .environment(
                    keyPath,
                    environmentRegistry.insertOrReplace(
                        self.content(environmentRegistry),
                        for: KeyType.self
                    )
                )
        }
    }
}
