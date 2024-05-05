//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import SwiftUI

typealias AnyStoredData = SwiftfinStore.V1.AnyData

extension SwiftfinStore.V1 {

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
    final class AnyData: CoreStoreObject {

        @Field.Stored("data")
        var data: Data? = nil

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

        let clause = From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$key == key && \.$domain == domain)

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

        let clause = From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$key == key && \.$domain == domain)

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

    // TODO: pass transaction along?

    /// Delete all data with the given `ownerID`
    ///
    /// Note: if `domain == nil`, will default to "none" to avoid local typing issues.
    static func deleteAll(ownerID: String) throws {

        let clause = From<AnyStoredData>()
            .where(\.$ownerID == ownerID)

        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(clause)

            transaction.delete(values)
        }
    }

    /// Delete all data with the given `ownerID` and `domain`
    ///
    /// Note: if `domain == nil`, will default to "none" to avoid local typing issues.
    static func deleteAll(ownerID: String, domain: String? = nil) throws {

        let domain = domain ?? "none"

        let clause = From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$domain == domain)

        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(clause)

            transaction.delete(values)
        }
    }

    /// Note: if `domain == nil`, will default to "none" to avoid local typing issues.
    static func delete(key: String, ownerID: String, domain: String? = nil) throws {

        let domain = domain ?? "none"

        let clause = From<AnyStoredData>()
            .where(\.$ownerID == ownerID && \.$key == key && \.$domain == domain)

        try SwiftfinStore.dataStack.perform { transaction in
            let values = try transaction.fetchAll(clause)

            transaction.delete(values)
        }
    }
}
