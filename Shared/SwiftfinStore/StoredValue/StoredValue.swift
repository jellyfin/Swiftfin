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
    private var observable: _GenericStoredValueObservation<Value>

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

        enum StorageDestination {
            case defaults
            case sql
        }

        let defaultValue: () -> Value
        let field: String?
        let name: String
        let ownerID: String
        let storage: StorageDestination

        var _defaultKey: Defaults.Key<Value> {

            let resolvedName: String = if field == name || field == nil {
                name
            } else {
                "\(field!)-\(name)"
            }

            return Defaults.Key(
                resolvedName,
                suite: UserDefaults(suiteName: ownerID)!,
                default: defaultValue
            )
        }

        init(
            _ name: String,
            ownerID: String,
            field: String?,
            storage: StorageDestination = .sql,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.field = field
            self.name = name
            self.ownerID = ownerID

            // tvOS only supports user defaults storage
            #if os(tvOS)
            self.storage = .defaults
            #else
            self.storage = storage
            #endif
        }

        /// Always returns the given value and does not
        /// set anything to storage.
        init(always: @autoclosure @escaping () -> Value) {
            defaultValue = always
            field = nil
            name = "always"
            ownerID = ""
            storage = .defaults
        }
    }

    static subscript<Value: Codable>(key: Key<Value>) -> Value {
        get {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return key.defaultValue() }

            switch key.storage {
            case .defaults:
                return Defaults[key._defaultKey]
            case .sql:
                let fetchedValue: Value? = try? AnyStoredData.fetch(
                    ownerID: key.ownerID,
                    field: key.field ?? key.name,
                    key: key.name
                )

                return fetchedValue ?? key.defaultValue()
            }
        }
        set {
            guard key.name.isNotEmpty, key.ownerID.isNotEmpty else { return }

            switch key.storage {
            case .defaults:
                Defaults[key._defaultKey] = newValue
            case .sql:
                try? AnyStoredData.store(
                    value: newValue,
                    ownerID: key.ownerID,
                    field: key.field ?? key.name,
                    key: key.name
                )
            }
        }
    }
}
