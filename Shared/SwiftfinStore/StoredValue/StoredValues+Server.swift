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
        _ name: String?,
        ownerID: String,
        domain: String,
        _storageDestination: StoredValues.Key<Value>._StorageDestination = .defaults,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: ownerID,
            domain: domain,
            _storageDestination: _storageDestination,
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
                "servers",
                ownerID: "general",
                domain: "servers",
                _storageDestination: .sql,
                default: []
            )
        }

        static func publicInfo(id: String) -> Key<PublicSystemInfo> {
            ServerKey(
                "publicInfo",
                ownerID: id,
                domain: "publicInfo",
                default: .init()
            )
        }
    }
}
