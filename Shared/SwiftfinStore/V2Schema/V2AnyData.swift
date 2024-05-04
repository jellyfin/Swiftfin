//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import SwiftUI

typealias AnyStoredData = SwiftfinStore.V1.AnyData

#warning("TODO: finalize")

extension SwiftfinStore.V1 {

    /// Used to store arbitrary data with a `name` and `id`,
    /// typically an attached user `id`.
    ///
    /// Used instead of `UserDefaults` for large objects or
    /// potentially large collections of data.
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data? = nil

        #warning("TODO: rename ownerID / something similar")
        @Field.Stored("id")
        var id: String = ""

        @Field.Stored("name")
        var name: String = ""
    }
}

/// A wrapper for a:
///
/// - `Stored`: stored in Core Data
/// - `User`: a user
/// - `Value`: the stored value for a user
@propertyWrapper
struct StoredValue<Value: Codable>: DynamicProperty {

    @ObservedObject
    private var observable: Observable

    let defaultValue: () -> Value
    let id: String
    let name: String?

    var projectedValue: Binding<Value> { $observable.value }

    var wrappedValue: Value {
        get {
            guard let name, id != "defaultStoreID" else { return defaultValue() }
            guard let value: Value = try? AnyStoredData.fetchAnyData(id: id, name: name) else { return defaultValue() }

            return value
        }
        nonmutating set {
            guard let name, id != "defaultStoreID" else { return }
            try? AnyStoredData.storeAnyData(value: newValue, id: id, name: name)

            print("Stored: \(newValue)\n - id: \(id)\n - name: \(name)")
        }
    }

    /// Note: if `name` is `nil`, values will not be stored.
    init(
        name: String?,
        id: String = Container.userSession()?.user.id ?? "defaultStoreID",
        defaultValue: @autoclosure @escaping () -> Value
    ) {
        self.defaultValue = defaultValue
        self.id = id
        self.name = name

        self.observable = .init(
            id: id,
            name: name,
            value: defaultValue()
        )
    }

    func update() {}
}

extension StoredValue {

    final class Observable: ObservableObject {

        let id: String
        let name: String?
        var value: Value

        init(id: String, name: String?, value: Value) {
            self.id = id
            self.name = name
            self.value = value
        }
    }
}

@propertyWrapper
struct CurrentUserStoredValue<Value: Codable> {

    let key: CurrentUserStoredValues.Key<Value>

    init(_ key: CurrentUserStoredValues.Key<Value>) {
        self.key = key
    }

    var wrappedValue: Value {
        get { fatalError() }
        set {}
    }
}

enum CurrentUserStoredValues {

    enum Keys {}

    final class Key<Value: Codable> {

        let defaultValue: () -> Value
        let name: String
        let id: String

        init(
            name: String,
            id: String = Container.userSession()?.user.id ?? "defaultStoreID",
            defaultValue: @autoclosure @escaping () -> Value
        ) {
            self.defaultValue = defaultValue
            self.id = id
            self.name = name
        }
    }
}

extension CurrentUserStoredValues.Keys {

    static let userPolicy = CurrentUserStoredValues.Key(name: "userPolicy", defaultValue: "None")
}

extension AnyStoredData {

    static func fetchAnyData<Value: Codable>(id: String, name: String) throws -> Value? {
        let values = try SwiftfinStore.dataStack
            .fetchAll(
                From<AnyStoredData>()
                    .where(\.$id == id && \.$name == name)
            )
            .compactMap(\.data)
            .compactMap {
                try JSONDecoder().decode(Value.self, from: $0)
            }

        assert(values.count < 2, "More than one stored object for same name and id?")

        return values.first
    }

    static func storeAnyData<Value: Codable>(value: Value, id: String, name: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let existing = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(\.$id == id && \.$name == name)
            )

            assert(existing.count < 2, "More than one stored object for same name and id?")

            let encodedData = try JSONEncoder().encode(value)

            if let existingObject = existing.first {
                let edit = transaction.edit(existingObject)
                edit?.data = encodedData
            } else {
                let newData = transaction.create(Into<AnyStoredData>())

                newData.data = encodedData
                newData.id = id
                newData.name = name
            }
        }
    }
}
