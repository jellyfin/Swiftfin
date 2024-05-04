//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import Foundation
import SwiftUI

typealias AnyStoredData = SwiftfinStore.V1.AnyData

#warning("TODO: finalize")

extension SwiftfinStore.V1 {

    /// Used to store arbitrary data with a `name` and `ownerID`.
    ///
    /// Essentially just a bag-of-bytes model like UserDefaults, but for
    /// storing larger objects or potentially large collections of data.
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data? = nil

        @Field.Stored("name")
        var name: String = ""

        @Field.Stored("ownerID")
        var ownerID: String = ""
    }
}

/// A wrapper for a:
///
/// - `Stored`: stored in Core Data
/// - `User`: a user
/// - `Value`: the stored value for a user
@propertyWrapper
struct StoredValue<Value: Codable>: DynamicProperty {

//    @ObservedObject
//    private var observable: Observable

    let defaultValue: () -> Value
    let name: String
    let ownerID: String

//    var projectedValue: Binding<Value> { $observable.value }

    var wrappedValue: Value {
        get {
            guard name.isNotEmpty, ownerID.isNotEmpty else { return defaultValue() }
            guard let value: Value = try? AnyStoredData.fetch(name: name, ownerID: ownerID) else { return defaultValue() }

            return value
        }
        nonmutating set {
            guard name.isNotEmpty, ownerID.isNotEmpty else { return }
            try? AnyStoredData.store(value: newValue, name: name, ownerID: ownerID)
        }
    }

    /// Note: if `name` is `nil`, values will not be stored.
    init(
        name: String,
        ownerID: String,
        default defaultValue: @autoclosure @escaping () -> Value
    ) {
        self.defaultValue = defaultValue
        self.name = name
        self.ownerID = ownerID

//        self.observable = .init(
//            id: id,
//            name: name,
//            value: defaultValue()
//        )
    }

    init(_ key: StoredValues.Key<Value>) {
        self.defaultValue = key.defaultValue
        self.name = key.name
        self.ownerID = key.ownerID
    }

    func update() {}
}

extension StoredValue {

    final class Observable: ObservableObject {

        let id: String
        let name: String?
        var value: Value

        init(
            id: String,
            name: String?,
            value: Value
        ) {
            self.id = id
            self.name = name
            self.value = value
        }
    }
}

enum StoredValues {

    typealias Keys = _AnyKey

    class _AnyKey {
        typealias Key = StoredValues.Key

        #warning("TODO: actual swift format ignore comment")
        let swiftFormatIgnore = 1
    }

    final class Key<Value: Codable>: _AnyKey {

        let defaultValue: () -> Value
        let name: String
        let ownerID: String

        init(
            name: String,
            ownerID: String,
            default defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.ownerID = ownerID
            self.name = name
        }

        init(always: @autoclosure @escaping () -> Value) {
            defaultValue = always
            name = ""
            ownerID = ""
        }
    }
}

extension StoredValues.Keys {

    static func UserKey<Value: Codable>(name: String?, default defaultValue: Value) -> Key<Value> {
        guard let name else { return Key(always: defaultValue) }
        guard let currentUser = Container.userSession()?.user else {
            return Key(always: defaultValue)
        }

        return Key(name: name, ownerID: currentUser.id, default: defaultValue)
    }

//    static let userPolicy = StoredValues.Key(name: "userPolicy", defaultValue: "None")

    static func libraryDisplayType(parentID: String?) -> Key<LibraryDisplayType> {
        UserKey(name: parentID, default: Defaults[.Customization.Library.viewType])
    }
}

extension AnyStoredData {

    static func fetch<Value: Codable>(name: String, ownerID: String) throws -> Value? {
        let values = try SwiftfinStore.dataStack
            .fetchAll(
                From<AnyStoredData>()
                    .where(\.$ownerID == ownerID && \.$name == name)
            )
            .compactMap(\.data)
            .compactMap {
                try JSONDecoder().decode(Value.self, from: $0)
            }

        assert(values.count < 2, "More than one stored object for same name and id!")

        return values.first
    }

    static func store<Value: Codable>(value: Value, name: String, ownerID: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let existing = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(\.$ownerID == ownerID && \.$name == name)
            )

            assert(existing.count < 2, "More than one stored object for same name and id!")

            let encodedData = try JSONEncoder().encode(value)

            if let existingObject = existing.first {
                let edit = transaction.edit(existingObject)
                edit?.data = encodedData
            } else {
                let newData = transaction.create(Into<AnyStoredData>())

                newData.data = encodedData
                newData.ownerID = ownerID
                newData.name = name
            }
        }
    }
}
