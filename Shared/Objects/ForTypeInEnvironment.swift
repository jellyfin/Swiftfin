//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@propertyWrapper
struct ForTypeInEnvironment<KeyType, Value>: DynamicProperty {

    @Environment
    private var registry: TypeKeyedDictionary<Value>

    init(
        _ keyPath: WritableKeyPath<EnvironmentValues, TypeKeyedDictionary<Value>>
    ) {
        self._registry = Environment(keyPath)
    }

    var wrappedValue: Value? {
        registry[KeyType.self]
    }

    struct SetValue: ViewModifier {

        @Environment
        private var dictionary: TypeKeyedDictionary<Value>

        private let content: ((TypeKeyedDictionary<Value>) -> Value)?
        private let keyPath: WritableKeyPath<EnvironmentValues, TypeKeyedDictionary<Value>>

        init(
            _ value: ((Value?) -> Value)?,
            for keyPath: WritableKeyPath<EnvironmentValues, TypeKeyedDictionary<Value>>
        ) {
            self.keyPath = keyPath
            self._dictionary = Environment(keyPath)

            if let value = value {
                self.content = { existingDictionary in
                    let existingValue = existingDictionary[KeyType.self]
                    return value(existingValue)
                }
            } else {
                self.content = nil
            }
        }

        func body(content: Content) -> some View {
            content
                .environment(
                    keyPath,
                    dictionary.inserting(
                        type: KeyType.self,
                        value: self.content?(dictionary)
                    )
                )
        }
    }

    struct GetValue<ContentWithExtracted: View>: ViewModifier {

        @Environment
        private var dictionary: TypeKeyedDictionary<Value>

        private let contentWithExtracted: (Value) -> ContentWithExtracted
        private let keyPath: WritableKeyPath<EnvironmentValues, TypeKeyedDictionary<Value>>

        init(
            for keyPath: WritableKeyPath<EnvironmentValues, TypeKeyedDictionary<Value>>,
            @ViewBuilder content: @escaping (Value) -> ContentWithExtracted
        ) {
            self._dictionary = Environment(keyPath)
            self.contentWithExtracted = content
            self.keyPath = keyPath
        }

        func body(content: Content) -> some View {
            if let environmentValue = dictionary[KeyType.self] {
                contentWithExtracted(environmentValue)
            } else {
                content
            }
        }
    }
}
