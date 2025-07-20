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
import Logging

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

    private static func storeDirectory(base: URL) -> URL {
        base
            .appendingPathComponent(
                Bundle.main.bundleIdentifier ?? "com.CoreStore.DataStack",
                isDirectory: true
            )
    }

    private static func storeFileURL(base: URL) -> URL {
        storeDirectory(base: base)
            .appendingPathComponent("Swiftfin.sqlite")
    }

    // MARK: - Storage

    private static let storage: SQLiteStore = {
        SQLiteStore(
            fileURL: storeFileURL(base: .applicationSupportDirectory),
            migrationMappingProviders: [Mappings.userV1_V2]
        )
    }()

    // MARK: - Requires a Migration

    static func requiresMigration() throws -> Bool {
        try dataStack.requiredMigrationsForStorage(storage).isNotEmpty
    }

    // MARK: - Set Up Data Stack

    static func setupDataStack() async throws {

        let logger = Logging.Logger.swiftfin()

        #if os(tvOS)
        moveStoreFromCacheDirectory()
        #endif

        try await withCheckedThrowingContinuation { continuation in
            _ = dataStack.addStorage(storage) { result in
                switch result {
                case .success:
                    continuation.resume()
                case let .failure(error):
                    logger.error("Failed creating datastack with: \(error.localizedDescription)")
                    continuation.resume(throwing: JellyfinAPIError("Failed creating datastack with: \(error.localizedDescription)"))
                }
            }
        }
    }

    // tvOS used to store database in Caches directory,
    // don't crash application if unable to move
    static func moveStoreFromCacheDirectory() {

        let applicationSupportStoreURL = storeFileURL(base: .applicationSupportDirectory)
        let cachesStoreURL = storeFileURL(base: .cachesDirectory)
        let fileManager = FileManager.default

        guard !fileManager.fileExists(atPath: applicationSupportStoreURL.path(percentEncoded: false)),
              fileManager.fileExists(atPath: cachesStoreURL.path(percentEncoded: false)) else { return }

        do {
            try fileManager.createDirectory(at: storeDirectory(base: .applicationSupportDirectory), withIntermediateDirectories: true)
            try fileManager.moveItem(at: cachesStoreURL, to: applicationSupportStoreURL)
        } catch {
            let logger = Logging.Logger.swiftfin()
            logger.critical("Error moving caches store to application support directory: \(error.localizedDescription)")
        }
    }
}
