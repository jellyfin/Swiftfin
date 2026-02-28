//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import Logging
import SwiftUI

// TODO: typealias to `Setting`?
//       - introduce `UserSetting` and `ServerSetting`
//         that automatically namespace

/// A property wrapper for a stored `AnyData` object.
@propertyWrapper
struct StoredValue<Value: Storable>: DynamicProperty {

    @ObservedObject
    private var observable: _GenericValueObservation<Value>

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
        self.observable = .init(key)
    }

    mutating func update() {
        _observable.update()
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
    final class Key<Value: Storable>: _AnyKey {

        enum _StorageDestination {
            case defaults
            case sql
        }

        let defaultValue: () -> Value
        let domain: String?
        let name: String
        let ownerID: String
        let _storageDestination: _StorageDestination

        var _defaultKey: Defaults.Key<Value> {
            Defaults.Key(
                name,
                suite: UserDefaults(suiteName: ownerID)!,
                default: defaultValue
            )
        }

        #if os(tvOS)
        init(
            _ name: String,
            ownerID: String,
            domain: String?,
            _storageDestination: _StorageDestination = .defaults,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.domain = domain
            self.name = name
            self.ownerID = ownerID
            self._storageDestination = _storageDestination
        }
        #else
        init(
            _ name: String,
            ownerID: String,
            domain: String?,
            _storageDestination: _StorageDestination = .sql,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.domain = domain
            self.name = name
            self.ownerID = ownerID
            self._storageDestination = _storageDestination
        }
        #endif

        /// Always returns the given value and does not
        /// set anything to storage.
        init(always: @autoclosure @escaping () -> Value) {
            defaultValue = always
            domain = nil
            name = "always"
            ownerID = ""
            _storageDestination = .defaults
        }
    }

    static subscript<Value: Codable>(key: Key<Value>) -> Value {
        get {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

            switch key._storageDestination {
            case .defaults:
                return Defaults[key._defaultKey]
            case .sql:
                let fetchedValue: Value? = try? AnyStoredData.fetch(
                    key.name,
                    ownerID: key.ownerID,
                    domain: key.domain
                )

                return fetchedValue ?? key.defaultValue()
            }
        }
        set {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }

            switch key._storageDestination {
            case .defaults:
                Defaults[key._defaultKey] = newValue
            case .sql:
                try? AnyStoredData.store(
                    value: newValue,
                    key: key.name,
                    ownerID: key.ownerID,
                    domain: key.domain ?? ""
                )
            }
        }
    }
}
