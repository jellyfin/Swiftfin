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
protocol _StoredValueObservable<Value>: ObservableObject {
    associatedtype Value: Storable

    var key: StoredValues.Key<Value> { get }
    var value: Value { get set }

    func observe()
}

@MainActor
final class _GenericStoredValueObservation<Value: Storable>: ObservableObject {

    private let key: StoredValues.Key<Value>
    private var observable: (any _StoredValueObservable<Value>)!

    var value: Value {
        get {
            observable.value
        }
        set {
            observable.value = newValue
        }
    }

    init(_ key: StoredValues.Key<Value>) {
        self.key = key
        self.observable = nil

        switch key.storage {
        case .defaults:
            observable = DefaultsObservable<Value>(key) { [weak self] in
                self?.objectWillChange.send()
            }
        case .sql:
            observable = SQLObservable<Value>(key) { [weak self] in
                self?.objectWillChange.send()
            }
        }

        observable.observe()
    }
}
