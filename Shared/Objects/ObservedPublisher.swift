//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation

/// Observable object property wrapper that allows observing
/// another `Publisher`.
@propertyWrapper
final class ObservedPublisher<Value>: ObservableObject {

    @Published
    private(set) var wrappedValue: Value

    var projectedValue: AnyPublisher<Value, Never> {
        $wrappedValue
            .eraseToAnyPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    init<P: Publisher>(
        wrappedValue: Value,
        observing publisher: P
    ) where P.Output == Value, P.Failure == Never {
        self.wrappedValue = wrappedValue

        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.wrappedValue = newValue
            }
            .store(in: &cancellables)
    }

    static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: KeyPath<T, Value>,
        storage storageKeyPath: KeyPath<T, ObservedPublisher<Value>>
    ) -> Value where T.ObjectWillChangePublisher == ObservableObjectPublisher {
        let wrapper = instance[keyPath: storageKeyPath]

        wrapper.objectWillChange
            .sink { [weak instance] _ in
                instance?.objectWillChange.send()
            }
            .store(in: &wrapper.cancellables)

        return wrapper.wrappedValue
    }
}
