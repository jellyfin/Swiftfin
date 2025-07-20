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
            .appendingPathComponent(bundleIdentifier, isDirectory: true)

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

        /// Remove the old Swiftfin data if the new data exists then safely return
        guard !fileManager.fileExists(atPath: newDatabase.path) else {
            try fileManager.removeItem(at: oldDatabase)
            return
        }

        /// Attempt to create the Application Support directory if it does not exist
        /// This directory should `always` exist but just in case
        if !fileManager.fileExists(atPath: newDirectory.path) {
            try fileManager.createDirectory(
                at: newDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }

        /// Identify any old Swiftfin files in the old Caches Directory
        let oldFiles = try fileManager.contentsOfDirectory(at: oldCoreStoreDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("Swiftfin") }

        /// Move any old Swiftfin files in the old Caches Directory to the Application Support directory
        for file in oldFiles {
            let fileName = file.lastPathComponent
            let destinationURL = newDirectory.appendingPathComponent(fileName)
            try fileManager.moveItem(at: file, to: destinationURL)
        }
    }
}
