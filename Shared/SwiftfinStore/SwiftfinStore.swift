//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import JellyfinAPI
import Logging

typealias AnyStoredData = SwiftfinStore.V3.AnyData

typealias ServerState = SwiftfinStore.State.Server
typealias UserState = SwiftfinStore.State.User

enum SwiftfinStore {

    enum V1 {}

    enum V2 {}

    enum V3 {}

    enum State {}
}

extension SwiftfinStore {

    private struct V1ServerSnapshot {
        let id: String
        let name: String
        let currentURI: String
        let uris: Set<String>
    }

    private struct V1UserSnapshot {
        let id: String
        let username: String
        let serverID: String?
        let accessToken: String?
    }

    private struct V2AnyDataSnapshot {
        let data: Data?
        let ownerID: String
        let domain: String
        let key: String
    }

    static let dataStack: DataStack = {
        DataStack(
            V1.schema,
            V2.schema,
            V3.schema,
            migrationChain: ["V1", "V2", "V3"]
        )
    }()

    private static let storage: SQLiteStore = {
        SQLiteStore(
            fileName: "Swiftfin.sqlite"
        )
    }()

    private static let appOwnerID = "swiftfinApp"

    static func setupDataStack() async throws {
        var migrationTypes = try dataStack.requiredMigrationsForStorage(storage)

        if try await manuallyMigrateV1ToV2IfNeeded(for: migrationTypes) {
            migrationTypes = try dataStack.requiredMigrationsForStorage(storage)
        }

        try await manuallyMigrateV2ToV3IfNeeded(for: migrationTypes)
        try await addStorage(storage, to: dataStack)
    }

    private static func manuallyMigrateV1ToV2IfNeeded(
        for migrationTypes: [MigrationType]
    ) async throws -> Bool {
        guard hasMigrationStep(from: "V1", to: "V2", in: migrationTypes) else { return false }
        let sourceStoreURL = storage.fileURL
        try await withTemporaryStoreURL(fileName: sourceStoreURL.lastPathComponent) { temporaryStoreURL in
            let snapshots = try await loadV1Snapshots(from: sourceStoreURL)
            try await createV2Store(
                at: temporaryStoreURL,
                servers: snapshots.servers,
                users: snapshots.users
            )
            try replaceSQLiteStore(at: sourceStoreURL, with: temporaryStoreURL)
        }

        return true
    }

    private static func manuallyMigrateV2ToV3IfNeeded(
        for migrationTypes: [MigrationType]
    ) async throws {
        guard hasMigrationStep(from: "V2", to: "V3", in: migrationTypes) else { return }
        let sourceStoreURL = storage.fileURL

        try await withTemporaryStoreURL(fileName: sourceStoreURL.lastPathComponent) { temporaryStoreURL in
            let anyDataSnapshots = try await loadV2AnyDataSnapshots(from: sourceStoreURL)
            let legacyStates = try await loadV2LegacyStates(from: sourceStoreURL)
            try await createV3Store(
                at: temporaryStoreURL,
                anyData: anyDataSnapshots,
                servers: legacyStates.servers,
                users: legacyStates.users
            )
            try replaceSQLiteStore(at: sourceStoreURL, with: temporaryStoreURL)

            // Manually migrate SQL to Defaults, knowingly
            // only keeping these values
            #if os(tvOS)
            StoredValues[.Server.servers] = legacyStates.servers
            StoredValues[.User.users] = legacyStates.users
            #endif
        }
    }

    private static func withTemporaryStoreURL<T>(
        fileName: String,
        _ work: (URL) async throws -> T
    ) async throws -> T {
        let temporaryRootURL = URL.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try FileManager.default.createDirectory(at: temporaryRootURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRootURL) }

        let temporaryStoreURL = temporaryRootURL.appendingPathComponent(fileName, isDirectory: false)
        return try await work(temporaryStoreURL)
    }

    private static func hasMigrationStep(
        from sourceVersion: String,
        to destinationVersion: String,
        in migrationTypes: [MigrationType]
    ) -> Bool {
        migrationTypes.contains { migrationType in
            switch migrationType {
            case let .heavyweight(source, destination),
                 let .lightweight(source, destination):
                source == sourceVersion && destination == destinationVersion
            case .none:
                false
            }
        }
    }

    private static func loadV1Snapshots(
        from sourceStoreURL: URL
    ) async throws -> (servers: [V1ServerSnapshot], users: [V1UserSnapshot]) {
        let sourceStack = DataStack(V1.schema)
        let sourceStorage = SQLiteStore(fileURL: sourceStoreURL)
        try await addStorage(sourceStorage, to: sourceStack)

        let servers = try sourceStack.fetchAll(From<SwiftfinStore.V1.StoredServer>())
            .map {
                V1ServerSnapshot(
                    id: $0.id,
                    name: $0.name,
                    currentURI: $0.currentURI,
                    uris: $0.uris
                )
            }

        let users = try sourceStack.fetchAll(From<SwiftfinStore.V1.StoredUser>())
            .map {
                V1UserSnapshot(
                    id: $0.id,
                    username: $0.username,
                    serverID: $0.server?.id,
                    accessToken: $0.accessToken?.value
                )
            }

        return (servers, users)
    }

    private static func createV2Store(
        at destinationStoreURL: URL,
        servers: [V1ServerSnapshot],
        users: [V1UserSnapshot]
    ) async throws {
        let destinationStack = DataStack(V2.schema)
        let destinationStorage = SQLiteStore(fileURL: destinationStoreURL)
        try await addStorage(destinationStorage, to: destinationStack)

        try destinationStack.perform { transaction in
            var v2ServersByID: [String: SwiftfinStore.V2.StoredServer] = [:]
            for server in servers {
                let newServer = transaction.create(Into<SwiftfinStore.V2.StoredServer>())
                let urls = transformServerURLs(server.uris)

                newServer.id = server.id
                newServer.name = server.name
                newServer.urls = urls
                newServer.currentURL = transformCurrentServerURL(server.currentURI, urls: urls)

                v2ServersByID[newServer.id] = newServer
            }

            for user in users {
                let newUser = transaction.create(Into<SwiftfinStore.V2.StoredUser>())

                newUser.id = user.id
                newUser.username = user.username
                if let serverID = user.serverID {
                    newUser.server = v2ServersByID[serverID]
                }

                persistAccessTokenToKeychain(
                    userID: newUser.id,
                    accessToken: user.accessToken
                )
            }
        }
    }

    private static func loadV2AnyDataSnapshots(from sourceStoreURL: URL) async throws -> [V2AnyDataSnapshot] {
        let sourceStack = DataStack(V2.schema)
        let sourceStorage = SQLiteStore(fileURL: sourceStoreURL)
        try await addStorage(sourceStorage, to: sourceStack)

        return try sourceStack.fetchAll(From<SwiftfinStore.V2.AnyData>())
            .map {
                V2AnyDataSnapshot(
                    data: $0.data,
                    ownerID: $0.ownerID,
                    domain: $0.domain,
                    key: $0.key
                )
            }
    }

    private static func createV3Store(
        at destinationStoreURL: URL,
        anyData: [V2AnyDataSnapshot],
        servers: [ServerState],
        users: [UserState]
    ) async throws {
        let destinationStack = DataStack(V3.schema)
        let destinationStorage = SQLiteStore(fileURL: destinationStoreURL)
        try await addStorage(destinationStorage, to: destinationStack)

        try destinationStack.perform { transaction in
            func upsertAnyData(ownerID: String, field: String, key: String, data: Data?) throws {
                let ownerFilter: Where<SwiftfinStore.V3.AnyData> = Where(\.$ownerID == ownerID)
                let fieldFilter: Where<SwiftfinStore.V3.AnyData> = Where(\.$field == field)
                let keyFilter: Where<SwiftfinStore.V3.AnyData> = Where(\.$key == key)
                let existing = try transaction.fetchOne(
                    From<SwiftfinStore.V3.AnyData>()
                        .where(ownerFilter && fieldFilter && keyFilter)
                )

                if let existing {
                    existing.data = data
                } else {
                    let newEntry = transaction.create(Into<SwiftfinStore.V3.AnyData>())
                    newEntry.ownerID = ownerID
                    newEntry.field = field
                    newEntry.key = key
                    newEntry.data = data
                }
            }

            for entry in anyData {
                try upsertAnyData(
                    ownerID: entry.ownerID,
                    field: entry.domain,
                    key: entry.key,
                    data: entry.data
                )
            }

            try upsertAnyData(
                ownerID: appOwnerID,
                field: "servers",
                key: "servers",
                data: JSONEncoder().encode(servers.sorted(using: \.name))
            )

            try upsertAnyData(
                ownerID: appOwnerID,
                field: "users",
                key: "users",
                data: JSONEncoder().encode(users.sorted(using: \.username))
            )
        }
    }

    private static func replaceSQLiteStore(at destinationStoreURL: URL, with sourceStoreURL: URL) throws {
        let fileManager = FileManager.default
        try removeSQLiteArtifacts(at: destinationStoreURL, using: fileManager)
        try moveSQLiteArtifacts(from: sourceStoreURL, to: destinationStoreURL, using: fileManager)
    }

    private static func sqliteArtifactURLs(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: "\(storeURL.path)-shm"),
            URL(fileURLWithPath: "\(storeURL.path)-wal"),
        ]
    }

    private static func removeSQLiteArtifacts(at storeURL: URL, using fileManager: FileManager) throws {
        for url in sqliteArtifactURLs(for: storeURL) where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private static func moveSQLiteArtifacts(
        from sourceStoreURL: URL,
        to destinationStoreURL: URL,
        using fileManager: FileManager
    ) throws {
        let sourceURLs = sqliteArtifactURLs(for: sourceStoreURL)
        let destinationURLs = sqliteArtifactURLs(for: destinationStoreURL)

        for (sourceURL, destinationURL) in zip(sourceURLs, destinationURLs) where fileManager.fileExists(atPath: sourceURL.path) {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
        }
    }

    private static func loadV2LegacyStates(
        from sourceStoreURL: URL
    ) async throws -> (servers: [ServerState], users: [UserState]) {
        let sourceStack = DataStack(V2.schema)
        let sourceStorage = SQLiteStore(fileURL: sourceStoreURL)
        try await addStorage(sourceStorage, to: sourceStack)

        let servers = try sourceStack.fetchAll(From<SwiftfinStore.V2.StoredServer>()).map(\.state)
        let users = try sourceStack.fetchAll(From<SwiftfinStore.V2.StoredUser>()).map(\.state)

        return (servers, users)
    }

    private static func addStorage(_ storage: SQLiteStore, to stack: DataStack) async throws {
        try await withCheckedThrowingContinuation { continuation in
            _ = stack.addStorage(storage) { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    continuation.resume(throwing: ErrorMessage("Failed creating datastack with: \(error.localizedDescription)"))
                }
            }
        }
    }

    static func accessToken(for sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject) -> String? {
        let tokenFromAttribute = sourceObject["accessToken"] as? String
        let tokenFromRelationship = (sourceObject["accessToken"] as? NSObject)?
            .value(forKey: "value") as? String

        return tokenFromAttribute ?? tokenFromRelationship
    }

    static func persistAccessTokenToKeychain(userID: String, accessToken: String?) {
        guard let accessToken else { return }
        Container.shared.keychainService().set(accessToken, forKey: "\(userID)-accessToken")
    }

    static func transformServerURLs(_ uris: Set<String>) -> Set<URL> {
        Set(uris.compactMap(URL.init(string:)))
    }

    static func transformCurrentServerURL(_ currentURI: String, urls: Set<URL>) -> URL {
        URL(string: currentURI) ?? urls.first ?? .init(string: "/")!
    }
}
