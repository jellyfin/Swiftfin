//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

extension SwiftfinStore.V1 {

    static let schema = CoreStoreSchema(
        modelVersion: "V1",
        entities: [
            Entity<StoredServer>("Server"),
            Entity<StoredUser>("User"),
        ],
        versionLock: [
            "Server": [
                0x4E8_8201_635C_2BB5,
                0x7A7_85D8_A65D_177C,
                0x3FE6_7B5B_D402_6EEE,
                0x8893_16D4_188E_B136,
            ],
            "User": [
                0x1001_44F1_4D4D_5A31,
                0x828F_7943_7D0B_4C03,
                0x3824_5761_B815_D61A,
                0x3C1D_BF68_E42B_1DA6,
            ],
        ]
    )
}
