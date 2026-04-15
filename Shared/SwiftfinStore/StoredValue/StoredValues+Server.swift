//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// TODO: also have matching properties on `ServerState` that get/set values

// MARK: keys

extension StoredValues.Keys {

    static func ServerKey<Value: Storable>(
        _ name: String? = nil,
        ownerID: String,
        field: String,
        storage: StoredValues.Key<Value>.StorageDestination = .defaults,
        default defaultValue: Value
    ) -> Key<Value> {
        Key(
            name ?? field,
            ownerID: ownerID,
            field: field,
            storage: storage,
            default: defaultValue
        )
    }

    static func ServerKey<Value: Storable>(always: Value) -> Key<Value> {
        Key(always: always)
    }
}

// MARK: values

extension ServerState: _DefaultsSerializable {}
extension ServerState: Storable {}
extension PublicSystemInfo: @retroactive _DefaultsSerializable {}
extension PublicSystemInfo: Storable {}

extension StoredValues.Keys {

    enum Server {

        static var servers: Key<[ServerState]> {
            ServerKey(
                ownerID: "swiftfinApp",
                field: "servers",
                storage: .sql,
                default: []
            )
        }

        static func publicInfo(id: String) -> Key<PublicSystemInfo> {
            ServerKey(
                ownerID: id,
                field: "publicInfo",
                default: .init()
            )
        }
    }
}
