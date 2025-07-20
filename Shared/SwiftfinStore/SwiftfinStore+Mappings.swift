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

#if os(tvOS)

    // MARK: - Migrate from Old tvOS Location to New

    static func migrateFromOldLocation() throws {
        let fileManager = FileManager.default
        
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(
            .cachesDirectory,
            .userDomainMask,
            true
        ).first!
        
        let oldDatabaseDirectory = URL(fileURLWithPath: cachesDirectory)
        
        let applicationSupportDirectory = NSSearchPathForDirectoriesInDomains(
            .applicationSupportDirectory,
            .userDomainMask,
            true
        ).first!
        
        let newDatabaseDirectory = URL(fileURLWithPath: applicationSupportDirectory)
            .appendingPathComponent("Swiftfin")
        
        let oldDatabasePath = oldDatabaseDirectory.appendingPathComponent("Swiftfin.sqlite")
        let newDatabasePath = newDatabaseDirectory.appendingPathComponent("Swiftfin.sqlite")
        
        guard fileManager.fileExists(atPath: oldDatabasePath.path) else {
            return
        }
        
        guard !fileManager.fileExists(atPath: newDatabasePath.path) else {
            try fileManager.removeItem(at: oldDatabasePath)
            return
        }
        
        try fileManager.createDirectory(
            at: newDatabaseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        let oldFiles = try fileManager.contentsOfDirectory(at: oldDatabaseDirectory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("Swiftfin") }
        
        for file in oldFiles {
            let fileName = file.lastPathComponent
            let destinationURL = newDatabaseDirectory.appendingPathComponent(fileName)
            try fileManager.moveItem(at: file, to: destinationURL)
        }
    }
#endif
}
