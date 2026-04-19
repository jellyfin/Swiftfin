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
            Entity<StoredAccessToken>("AccessToken"),
            Entity<StoredServer>("Server"),
            Entity<StoredUser>("User"),
        ],
        versionLock: [
            "AccessToken": [
                0xA8C4_75E8_7449_4BB1,
                0x7948_6E93_449F_0B3D,
                0xA7DC_4A00_0354_1EDB,
                0x9418_3FAE_7580_EF72,
            ],
            "Server": [
                0x936B_46AC_D8E8_F0E3,
                0x5989_0D4D_9F3F_885F,
                0x819C_F7A4_ABF9_8B22,
                0xE161_25C5_AF88_5A06,
            ],
            "User": [
                0x845D_E08A_74BC_53ED,
                0xE95A_406A_29F3_A5D0,
                0x9EDA_7328_21A1_5EA9,
                0xB5A_FA53_1E41_CE8A,
            ],
        ]
    )
}
