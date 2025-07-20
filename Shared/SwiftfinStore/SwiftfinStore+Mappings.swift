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
import KeychainSwift

extension SwiftfinStore {
    enum Mappings {}
}

extension SwiftfinStore.Mappings {

    // MARK: User V1 to V2

    // V1 users had access token stored in Core Data.
    // Move to the Keychain.

    static let userV1_V2 = {
        CustomSchemaMappingProvider(
            from: "V1",
            to: "V2",
            entityMappings: [
                .transformEntity(
                    sourceEntity: "User",
                    destinationEntity: "User",
                    transformer: { sourceObject, createDestinationObject in

                        // move access token to Keychain
                        if let id = sourceObject["id"] as? String, let accessToken = sourceObject["accessToken"] as? String {
                            Container.shared.keychainService().set(accessToken, forKey: "\(id)-accessToken")
                        } else {
                            fatalError("wtf")
                        }

                        let destinationObject = createDestinationObject()
                        destinationObject.enumerateAttributes { attribute, sourceAttribute in
                            if let sourceAttribute {
                                destinationObject[attribute] = sourceObject[attribute]
                            }
                        }
                    }
                ),
            ]
        )
    }()

    // MARK: - Migrate from Old tvOS Location to New

    static func migrateFromOldLocation(bundleIdentifier: String) throws {
        let fileManager = FileManager.default

        /// Get the default tvOS directory for CoreStore
        let oldCoreStoreDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!

        let oldDatabase = oldCoreStoreDirectory
            .appendingPathComponent("Swiftfin.sqlite")

        /// Safely return if there is no old Swiftfin data to migrate
        guard fileManager.fileExists(atPath: oldDatabase.path) else {
            return
        }

        /// Get the Application Support directory for all new CoreStore
        let newDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(bundleIdentifier, isDirectory: true)

        let newDatabase = newDirectory
            .appendingPathComponent("Swiftfin.sqlite")

        /// Skip migration if new database already exists and is not empty
        if fileManager.fileExists(atPath: newDatabase.path) {
            if let attrs = try? fileManager.attributesOfItem(atPath: newDatabase.path),
               let size = attrs[.size] as? NSNumber,
               size.intValue > 0
            {
                /// Clean up old files only if new database has content
                try? fileManager.removeItem(at: oldDatabase)
                return
            }
        }

        /// Create the Application Support directory if it does not exist
        if !fileManager.fileExists(atPath: newDirectory.path) {
            try fileManager.createDirectory(
                at: newDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        /// Get all old Swiftfin files
        let oldFiles = try fileManager.contentsOfDirectory(at: oldCoreStoreDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("Swiftfin") }

        /// Move files atomically - only delete old files after ALL moves succeed
        for file in oldFiles {
            let fileName = file.lastPathComponent
            let destinationURL = newDirectory.appendingPathComponent(fileName)

            /// Remove destination if it exists to avoid conflicts
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }

            try fileManager.moveItem(at: file, to: destinationURL)
        }
    }
}
