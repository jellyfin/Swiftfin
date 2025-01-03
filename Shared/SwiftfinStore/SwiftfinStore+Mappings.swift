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
}
