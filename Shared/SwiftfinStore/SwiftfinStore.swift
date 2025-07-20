//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import JellyfinAPI

typealias AnyStoredData = SwiftfinStore.V2.AnyData
typealias ServerModel = SwiftfinStore.V2.StoredServer
typealias UserModel = SwiftfinStore.V2.StoredUser

typealias ServerState = SwiftfinStore.State.Server
typealias UserState = SwiftfinStore.State.User

// MARK: Namespaces

extension Container {
    var dataStore: Factory<DataStack> { self { SwiftfinStore.dataStack }.singleton }
}

enum SwiftfinStore {

    /// Namespace for V1 objects
    enum V1 {}

    /// Namespace for V2 objects
    enum V2 {}

    /// Namespace for state objects
    enum State {}
}

// MARK: dataStack

// TODO: cleanup

extension SwiftfinStore {

    static let dataStack: DataStack = {
        DataStack(
            V1.schema,
            V2.schema,
            migrationChain: ["V1", "V2"]
        )
    }()

    // MARK: - Bundle Identifier

    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack"

    // MARK: - Storage

    private static let storage: SQLiteStore = {
        let applicationSupportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let appDirectory = applicationSupportDirectory.appendingPathComponent(
            bundleIdentifier,
            isDirectory: true
        )

        return SQLiteStore(
            fileURL: appDirectory.appendingPathComponent("Swiftfin.sqlite"),
            migrationMappingProviders: [Mappings.userV1_V2]
        )
    }()

    // MARK: - Requires a Migration

    static func requiresMigration() throws -> Bool {
        try dataStack.requiredMigrationsForStorage(storage).isNotEmpty
    }

    // MARK: - Set Up Data Stack

    static func setupDataStack() async throws {
        #if os(tvOS)
        try Mappings.migrateFromOldLocation(bundleIdentifier: bundleIdentifier)
        #endif

        try await withCheckedThrowingContinuation { continuation in
            _ = dataStack.addStorage(storage) { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    Container.shared.logService().error("Failed creating datastack with: \(error.localizedDescription)")
                    continuation.resume(throwing: JellyfinAPIError("Failed creating datastack with: \(error.localizedDescription)"))
                }
            }
        }
    }
}
