//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Foundation
import SwiftUI

/// A property wrapper for a stored `AnyData` object.
@propertyWrapper
struct StoredValue<Value: Codable>: DynamicProperty {

    @ObservedObject
    private var observable: Observable

    let key: StoredValues.Key<Value>

    var projectedValue: Binding<Value> {
        $observable.value
    }

    var wrappedValue: Value {
        get {
            observable.value
        }
        nonmutating set {
            observable.value = newValue
        }
    }

    init(_ key: StoredValues.Key<Value>) {
        self.key = key
        self.observable = .init(key: key)
    }

    mutating func update() {
        _observable.update()
    }
}

extension StoredValue {

    final class Observable: ObservableObject {

        let key: StoredValues.Key<Value>

        let objectWillChange = ObservableObjectPublisher()

        var value: Value {
            get {
                guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

                let fetchedValue: Value? = try? AnyStoredData.fetch(
                    key.name,
                    ownerID: key.ownerID,
                    domain: key.domain
                )

                return fetchedValue ?? key.defaultValue()
            }
            set {
                guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }

                objectWillChange.send()

                try? AnyStoredData.store(
                    value: newValue,
                    key: key.name,
                    ownerID: key.ownerID,
                    domain: key.domain ?? ""
                )
            }
        }

        init(key: StoredValues.Key<Value>) {
            self.key = key
        }
    }
}

enum StoredValues {

    typealias Keys = _AnyKey

    // swiftformat:disable enumnamespaces
    class _AnyKey {
        typealias Key = StoredValues.Key
    }

    /// A key to an `AnyData` object.
    ///
    /// - Important: if `name` or `ownerID` are empty, the default value
    ///              will always be retrieved and nothing will be set.
    final class Key<Value: Codable>: _AnyKey {

        let defaultValue: () -> Value
        let domain: String?
        let name: String
        let ownerID: String

        init(
            _ name: String,
            ownerID: String,
            domain: String?,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.domain = domain
            self.ownerID = ownerID
            self.name = name
        }

        /// Always returns the given value and does not
        /// set anything to storage.
        init(always: @autoclosure @escaping () -> Value) {
            defaultValue = always
            domain = nil
            name = ""
            ownerID = ""
        }
    }

    // TODO: find way that code isn't just copied from `Observable` above
    static subscript<Value: Codable>(key: Key<Value>) -> Value {
        get {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

            let fetchedValue: Value? = try? AnyStoredData.fetch(
                key.name,
                ownerID: key.ownerID,
                domain: key.domain
            )

            return fetchedValue ?? key.defaultValue()
        }
        set {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }

            try? AnyStoredData.store(
                value: newValue,
                key: key.name,
                ownerID: key.ownerID,
                domain: key.domain ?? ""
            )
        }
    }
}
