//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension AnyStoredData {

    static func fetch<Value: Codable>(ownerID: String, field: String, key: String) throws -> Value? {

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let fieldFilter: Where<AnyStoredData> = Where(\.$field == field)

        let clause = From<AnyStoredData>()
            .where(ownerFilter && keyFilter && fieldFilter)

        let values = try SwiftfinStore.dataStack
            .fetchAll(
                clause
            )
            .compactMap(\.data)
            .compactMap {
                try JSONDecoder().decode(Value.self, from: $0)
            }

        assert(values.count < 2, "More than one stored object for same name, id, and field!")

        return values.first
    }

    static func store(value: some Codable, ownerID: String, field: String, key: String) throws {

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let fieldFilter: Where<AnyStoredData> = Where(\.$field == field)

        let clause = From<AnyStoredData>()
            .where(ownerFilter && keyFilter && fieldFilter)

        try SwiftfinStore.dataStack.perform { transaction in
            let existing = try transaction.fetchAll(clause)

            assert(existing.count < 2, "More than one stored object for same name, id, and field!")

            let encodedData = try JSONEncoder().encode(value)

            if let existingObject = existing.first {
                let edit = transaction.edit(existingObject)
                edit?.data = encodedData
            } else {
                let newData = transaction.create(Into<AnyStoredData>())

                newData.data = encodedData
                newData.field = field
                newData.ownerID = ownerID
                newData.key = key
            }
        }
    }

    /// Creates a fetch clause to be used within local transactions
    static func fetchClause(ownerID: String) -> FetchChainBuilder<AnyStoredData> {
        From<AnyStoredData>()
            .where(\.$ownerID == ownerID)
    }

    /// Creates a fetch clause to be used within local transactions
    ///
    static func fetchClause(ownerID: String, field: String) -> FetchChainBuilder<AnyStoredData> {
        From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$field == field)
    }

    /// Creates a fetch clause to be used within local transactions
    ///
    static func fetchClause(ownerID: String, field: String, key: String) -> FetchChainBuilder<AnyStoredData> {

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let fieldFilter: Where<AnyStoredData> = Where(\.$field == field)

        return From<AnyStoredData>()
            .where(ownerFilter && keyFilter && fieldFilter)
    }

    /// Delete all data with the given `ownerID`
    ///
    /// Note: if performing deletion with another transaction, use `fetchClause`
    ///       instead to delete within the other transaction
    static func deleteAll(ownerID: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(fetchClause(ownerID: ownerID))

            transaction.delete(values)
        }
    }

    /// Delete all data with the given `ownerID` and `field`
    ///
    /// Note: if performing deletion with another transaction, use `fetchClause`
    ///       instead to delete within the other transaction
    static func deleteAll(ownerID: String, field: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(fetchClause(ownerID: ownerID, field: field))

            transaction.delete(values)
        }
    }

    /// Delete all data given `ownerID`, `field`, and `key`.
    ///
    /// Note: if performing deletion with another transaction, use `fetchClause`
    ///       instead to delete within the other transaction
    static func delete(ownerID: String, field: String, key: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(fetchClause(ownerID: ownerID, field: field, key: key))

            transaction.delete(values)
        }
    }
}
