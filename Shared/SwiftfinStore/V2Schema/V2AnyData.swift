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
import SwiftUI

extension SwiftfinStore.V2 {

    /// Used to store arbitrary data with a `name` and `ownerID`.
    ///
    /// Essentially just a bag-of-bytes model like UserDefaults, but for
    /// storing larger objects or arbitrary collection elements.
    ///
    /// Relationships generally take the form below, where `ownerID` is like
    /// an object, `domain`s are property names, and `key`s are values within
    /// the `domain`. An instance where `domain == key` is like a single-value
    /// property while a `domain` with many `keys` is like a dictionary.
    ///
    /// ownerID
    /// - domain
    ///   - key(s)
    /// - domain
    ///   - key(s)
    ///
    /// This can be useful to not require migrations on model objects for new
    /// "properties".
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data?

        @Field.Stored("domain")
        var domain: String = ""

        @Field.Stored("key")
        var key: String = ""

        @Field.Stored("ownerID")
        var ownerID: String = ""
    }
}

extension AnyStoredData {

    /// Note: if `domain == nil`, will default to "none" to avoid local typing issues.
    static func fetch<Value: Codable>(_ key: String, ownerID: String, domain: String? = nil) throws -> Value? {

        let domain = domain ?? "none"

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let domainFilter: Where<AnyStoredData> = Where(\.$domain == domain)

        let clause = From<AnyStoredData>()
            .where(ownerFilter && keyFilter && domainFilter)

        let values = try SwiftfinStore.dataStack
            .fetchAll(
                clause
            )
            .compactMap(\.data)
            .compactMap {
                try JSONDecoder().decode(Value.self, from: $0)
            }

        assert(values.count < 2, "More than one stored object for same name, id, and domain!")

        return values.first
    }

    /// Note: if `domain == nil`, will default to "none" to avoid local typing issues.
    static func store<Value: Codable>(value: Value, key: String, ownerID: String, domain: String? = nil) throws {

        let domain = domain ?? "none"

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let domainFilter: Where<AnyStoredData> = Where(\.$domain == domain)

        let clause = From<AnyStoredData>()
            .where(ownerFilter && keyFilter && domainFilter)

        try SwiftfinStore.dataStack.perform { transaction in
            let existing = try transaction.fetchAll(clause)

            assert(existing.count < 2, "More than one stored object for same name, id, and domain!")

            let encodedData = try JSONEncoder().encode(value)

            if let existingObject = existing.first {
                let edit = transaction.edit(existingObject)
                edit?.data = encodedData
            } else {
                let newData = transaction.create(Into<AnyStoredData>())

                newData.data = encodedData
                newData.domain = domain
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
    /// Note: if `domain == nil`, will default to "none"
    static func fetchClause(ownerID: String, domain: String? = nil) throws -> FetchChainBuilder<AnyStoredData> {
        let domain = domain ?? "none"

        return From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$domain == domain)
    }

    /// Creates a fetch clause to be used within local transactions
    ///
    /// Note: if `domain == nil`, will default to "none"
    static func fetchClause(key: String, ownerID: String, domain: String? = nil) throws -> FetchChainBuilder<AnyStoredData> {
        let domain = domain ?? "none"

        let ownerFilter: Where<AnyStoredData> = Where(\.$ownerID == ownerID)
        let keyFilter: Where<AnyStoredData> = Where(\.$key == key)
        let domainFilter: Where<AnyStoredData> = Where(\.$domain == domain)

        return From<AnyStoredData>()
            .where(ownerFilter && keyFilter && domainFilter)
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

    /// Delete all data with the given `ownerID` and `domain`
    ///
    /// Note: if performing deletion with another transaction, use `fetchClause`
    ///       instead to delete within the other transaction
    /// Note: if `domain == nil`, will default to "none"
    static func deleteAll(ownerID: String, domain: String? = nil) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(fetchClause(ownerID: ownerID, domain: domain))

            transaction.delete(values)
        }
    }

    /// Delete all data given `key`, `ownerID`, and `domain`.
    ///
    ///
    /// Note: if performing deletion with another transaction, use `fetchClause`
    ///       instead to delete within the other transaction
    /// Note: if `domain == nil`, will default to "none"
    static func delete(key: String, ownerID: String, domain: String? = nil) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(fetchClause(key: key, ownerID: ownerID, domain: domain))

            transaction.delete(values)
        }
    }
}
