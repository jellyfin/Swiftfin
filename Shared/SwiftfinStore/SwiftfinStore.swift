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

// MARK: Namespaces

extension Container {
    var dataStore: Factory<DataStack> {
        self { SwiftfinStore.dataStack }.singleton
    }
}

enum SwiftfinStore {

    /// Namespace for V1 objects
    enum V1 {}

    /// Namespace for V2 objects
    enum V2 {}

    /// Namespace for V3 objects
    enum V3 {}

    /// Namespace for state objects
    enum State {}
}

// MARK: dataStack

// TODO: cleanup

extension SwiftfinStore {

    private struct LegacyModelSnapshot {
        let servers: [ServerState]
        let users: [UserState]
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
            fileName: "Swiftfin.sqlite",
            migrationMappingProviders: [Mappings.userV1_V2, Mappings.anyDataV2_V3]
        )
    }()

    static func requiresMigration() throws -> Bool {
        try dataStack.requiredMigrationsForStorage(storage).isNotEmpty
    }

    static func setupDataStack() async throws {
        let migrationTypes = try dataStack.requiredMigrationsForStorage(storage)
        let legacyModelSnapshot = try await loadV2LegacyModelSnapshotIfNeeded(for: migrationTypes)

        try await addStorage(storage, to: dataStack)

        guard let legacyModelSnapshot else { return }

        StoredValues[.Server.servers] = legacyModelSnapshot.servers.sorted(using: \.name)
        StoredValues[.User.users] = legacyModelSnapshot.users.sorted(using: \.username)
    }

    private static func loadV2LegacyModelSnapshotIfNeeded(
        for migrationTypes: [MigrationType]
    ) async throws -> LegacyModelSnapshot? {
        let migratesIntoV3 = migrationTypes.contains {
            switch $0 {
            case let .heavyweight(_, destinationVersion), let .lightweight(_, destinationVersion):
                destinationVersion == "V3"
            case .none:
                false
            }
        }

        guard migratesIntoV3 else { return nil }

        let sourceStoreVersion = migrationTypes.compactMap { migrationType -> String? in
            switch migrationType {
            case let .heavyweight(sourceVersion, _), let .lightweight(sourceVersion, _):
                sourceVersion
            case .none:
                nil
            }
        }.first

        switch sourceStoreVersion {
        case "V2":
            return try await loadV2LegacyModelSnapshot()
        default:
            return nil
        }
    }

    private static func loadV2LegacyModelSnapshot() async throws -> LegacyModelSnapshot {
        let temporaryDataStack = DataStack(V2.schema)
        let temporaryStorage = SQLiteStore(fileName: "Swiftfin.sqlite")
        try await addStorage(temporaryStorage, to: temporaryDataStack)

        let servers = try temporaryDataStack.fetchAll(From<SwiftfinStore.V2.StoredServer>())
            .map(\.state)

        let users = try temporaryDataStack.fetchAll(From<SwiftfinStore.V2.StoredUser>())
            .map(\.state)

        return .init(servers: servers, users: users)
    }

    private static func addStorage(_ storage: SQLiteStore, to stack: DataStack) async throws {
        try await withCheckedThrowingContinuation { continuation in
            _ = stack.addStorage(storage) { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    Logger.swiftfin().error("Failed creating datastack with: \(error.localizedDescription)")
                    continuation.resume(throwing: ErrorMessage("Failed creating datastack with: \(error.localizedDescription)"))
                }
            }
        }
    }
}
